```verilog
module axidma #(
    parameter C_AXI_ID_WIDTH = 1,
    parameter C_AXI_ADDR_WIDTH = 32,
    parameter C_AXI_DATA_WIDTH = 32,
    localparam C_AXIL_ADDR_WIDTH = 5,
    localparam C_AXIL_DATA_WIDTH = 32,
    parameter [0:0] OPT_UNALIGNED = 1'b1,
    parameter [0:0] OPT_WRAPMEM = 1'b1,
    parameter LGFIFO = 8, // Assumed LGMAXBURST+1 for FIFO depth
    parameter LGLEN = C_AXI_ADDR_WIDTH,
    parameter [0:0] OPT_LOWPOWER = 1'b0,
    parameter [0:0] OPT_CLKGATE = OPT_LOWPOWER,
    parameter [C_AXI_ID_WIDTH-1:0] AXI_READ_ID = 0,
    parameter [C_AXI_ID_WIDTH-1:0] AXI_WRITE_ID = 0,
    parameter [7:0] ABORT_KEY = 8'h6d,
    localparam ADDRLSB = $clog2(C_AXI_DATA_WIDTH)-3,
    localparam AXILLSB = $clog2(C_AXIL_DATA_WIDTH)-3,
    localparam LGLENW = LGLEN-ADDRLSB
) (
    input wire S_AXI_ACLK,
    input wire S_AXI_ARESETN,
    input wire S_AXIL_AWVALID,
    output wire S_AXIL_AWREADY,
    input wire [C_AXIL_ADDR_WIDTH-1:0] S_AXIL_AWADDR,
    input wire [2:0] S_AXIL_AWPROT,
    input wire S_AXIL_WVALID,
    output wire S_AXIL_WREADY,
    input wire [C_AXIL_DATA_WIDTH-1:0] S_AXIL_WDATA,
    input wire [C_AXIL_DATA_WIDTH/8-1:0] S_AXIL_WSTRB,
    output reg S_AXIL_BVALID,
    input wire S_AXIL_BREADY,
    output wire [1:0] S_AXIL_BRESP,
    input wire S_AXIL_ARVALID,
    output wire S_AXIL_ARREADY,
    input wire [C_AXIL_ADDR_WIDTH-1:0] S_AXIL_ARADDR,
    input wire [2:0] S_AXIL_ARPROT,
    output reg S_AXIL_RVALID,
    input wire S_AXIL_RREADY,
    output reg [C_AXIL_DATA_WIDTH-1:0] S_AXIL_RDATA,
    output wire [1:0] S_AXIL_RRESP,
    output reg M_AXI_AWVALID,
    input wire M_AXI_AWREADY,
    output reg [C_AXI_ID_WIDTH-1:0] M_AXI_AWID,
    output reg [C_AXI_ADDR_WIDTH-1:0] M_AXI_AWADDR,
    output reg [2:0] M_AXI_AWSIZE,
    output reg [1:0] M_AXI_AWBURST,
    output reg M_AXI_AWLOCK,
    output reg [3:0] M_AXI_AWCACHE,
    output reg [2:0] M_AXI_AWPROT,
    output reg [3:0] M_AXI_AWQOS,
    output reg M_AXI_WVALID,
    input wire M_AXI_WREADY,
    output reg [C_AXI_DATA_WIDTH-1:0] M_AXI_WDATA,
    output reg [C_AXI_DATA_WIDTH/8-1:0] M_AXI_WSTRB,
    output reg M_AXI_WLAST,
    input wire M_AXI_BVALID,
    output reg M_AXI_BREADY,
    input wire [C_AXI_ID_WIDTH-1:0] M_AXI_BID,
    input wire [1:0] M_AXI_BRESP,
    output reg M_AXI_ARVALID,
    input wire M_AXI_ARREADY,
    output wire [C_AXI_ID_WIDTH-1:0] M_AXI_ARID,
    output reg [C_AXI_ADDR_WIDTH-1:0] M_AXI_ARADDR,
    output wire [2:0] M_AXI_ARSIZE,
    output wire [1:0] M_AXI_ARBURST,
    output wire M_AXI_ARLOCK,
    output wire [3:0] M_AXI_ARCACHE,
    output wire [2:0] M_AXI_ARPROT,
    output wire [3:0] M_AXI_ARQOS,
    input wire M_AXI_RVALID,
    output wire M_AXI_RREADY,
    input wire [C_AXI_ID_WIDTH-1:0] M_AXI_RID,
    input wire [C_AXI_DATA_WIDTH-1:0] M_AXI_RDATA,
    input wire M_AXI_RLAST,
    input wire [1:0] M_AXI_RRESP,
    output reg o_int
);

    // Internal Clocks and Reset
    reg S_AXI_ACLK_INT;
    reg S_AXI_ARESETN_INT;
    
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_ACLK_INT <= 1'b0;
            S_AXI_ARESETN_INT <= 1'b1;
        end else begin
            S_AXI_ACLK_INT <= S_AXI_ACLK;
            S_AXI_ARESETN_INT <= S_AXI_ARESETN;
        end
    end

    // State Machine
    typedef enum logic [2:0] {
        IDLE,
        AW_PREPARE,
        AW_SEND,
        AW_WAIT,
        W_PREPARE,
        W_SEND,
        W_WAIT,
        B_WAIT,
        AR_PREPARE,
        AR_SEND,
        AR_WAIT,
        R_PREPARE,
        R_SEND,
        R_WAIT,
        DONE
    } state_t;

    state_t current_state, next_state;
    logic [3:0] cmd_type; // 0: Write, 1: Read
    logic [C_AXI_ADDR_WIDTH-1:0] src_addr, dst_addr;
    logic [31:0] src_len, dst_len;
    logic [3:0] burst_len;
    logic [2:0] burst_type;
    logic [2:0] size;
    logic [3:0] qos;
    logic [2:0] prot;
    logic [C_AXI_ID_WIDTH-1:0] id;
    logic [C_AXI_DATA_WIDTH/8-1:0] wstrb;
    logic [C_AXI_DATA_WIDTH-1:0] wdata;
    logic wlast;
    logic arlast;
    logic [C_AXI_DATA_WIDTH-1:0] rdata;
    logic [1:0] rresp;
    logic [1:0] bresp;
    logic [C_AXI_ID_WIDTH-1:0] bid;
    logic [C_AXI_ADDR_WIDTH-1:0] last_addr;
    logic [C_AXI_ADDR_WIDTH-1:0] current_addr;
    logic [31:0] remaining_len;
    logic [31:0] total_len;
    logic [3:0] burst_count;
    logic [3:0] burst_remain;
    logic [C_AXI_DATA_WIDTH-1:0] fifo_wdata;
    logic [C_AXI_DATA_WIDTH/8-1:0] fifo_wstrb;
    logic [C_AXI_DATA_WIDTH-1:0] fifo_rdata;
    logic [C_AXI_DATA_WIDTH/8-1:0] fifo_rstrb;
    logic [3:0] fifo_wptr, fifo_rptr;
    logic [3:0] fifo_count;
    logic fifo_wr_en, fifo_rd_en;
    logic [C_AXI_DATA_WIDTH-1:0] rdata_reg;
    logic [1:0] rresp_reg;
    logic rlast_reg;
    logic [C_AXI_ID_WIDTH-1:0] rid_reg;
    logic [C_AXI_DATA_WIDTH-1:0] wdata_reg;
    logic [C_AXI_DATA_WIDTH/8-1:0] wstrb_reg;
    logic wlast_reg;
    logic [C_AXI_ID_WIDTH-1:0] awid_reg;
    logic [C_AXI_ADDR_WIDTH-1:0] awaddr_reg;
    logic [2:0] awsize_reg;
    logic [1:0] awburst_reg;
    logic awlock_reg;
    logic [3:0] awcache_reg;
    logic [2:0] awprot_reg;
    logic [3:0] awqos_reg;
    logic awvalid_reg;
    logic awready_reg;
    logic wvalid_reg;
    logic wready_reg;
    logic wlast_reg_int;
    logic bvalid_reg;
    logic bready_reg;
    logic arvalid_reg;
    logic arready_reg;
    logic arid_reg;
    logic araddr_reg;
    logic arsize_reg;
    logic arbust_reg;
    logic arlock_reg;
    logic arcache_reg;
    logic arprot_reg;
    logic arqos_reg;
    logic rvalid_reg;
    logic rready_reg;
    logic rid_reg_int;
    logic rdata_reg_int;
    logic rlast_reg_int;
    logic rresp_reg_int;
    logic [C_AXI_DATA_WIDTH-1:0] rdata_fifo;
    logic [C_AXI_DATA_WIDTH/8-1:0] rstrb_fifo;
    logic [3:0] rdata_fifo_ptr, rstrb_fifo_ptr;
    logic [3:0] rdata_fifo_count;
    logic rdata_wr_en, rdata_rd_en;
    logic [C_AXI_DATA_WIDTH-1:0] rdata_out;
    logic [1:0] rresp_out;
    logic rlast_out;
    logic [C_AXI_ID_WIDTH-1:0] rid_out;
    logic [C_AXI_DATA_WIDTH-1:0] wdata_out;
    logic [C_AXI_DATA_WIDTH/8-1:0] wstrb_out;
    logic wlast_out;
    logic [C_AXI_ID_WIDTH-1:0] awid_out;
    logic [C_AXI_ADDR_WIDTH-1:0] awaddr_out;
    logic [2:0] awsize_out;
    logic [1:0] awburst_out;
    logic awlock_out;
    logic [3:0] awcache_out;
    logic [2:0] awprot_out;
    logic [3:0] awqos_out;
    logic awvalid_out;
    logic awready_out;
    logic wvalid_out;
    logic wready_out;
    logic wlast_out_int;
    logic bvalid_out;
    logic bready_out;
    logic arvalid_out;
    logic arready_out;
    logic arid_out;
    logic araddr_out;
    logic arsize_out;
    logic arbust_out;
    logic arlock_out;
    logic arcache_out;
    logic arprot_out;
    logic arqos_out;
    logic rvalid_out;
    logic rready_out;
    logic rid_out_int;
    logic rdata_out_int;
    logic rlast_out_int;
    logic rresp_out_int;

    // Reset Logic
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            current_state <= IDLE;
            o_int <= 1'b0;
            // Clear all registers
            src_addr <= 0;
            dst_addr <= 0;
            src_len <= 0;
            dst_len <= 0;
            burst_len <= 0;
            burst_type <= 0;
            size <= 0;
            qos <= 0;
            prot <= 0;
            id <= 0;
            wstrb <= 0;
            wdata <= 0;
            wlast <= 0;
            arlast <= 0;
            rdata <= 0;
            rresp <= 0;
            bid <= 0;
            last_addr <= 0;
            current_addr <= 0;
            remaining_len <= 0;
            total_len <= 0;
            burst_count <= 0;
            burst_remain <= 0;
            fifo_wptr <= 0;
            fifo_rptr <= 0;
            fifo_count <= 0;
            rdata_reg <= 0;
            rresp_reg <= 0;
            rlast_reg <= 0;
            rid_reg <= 0;
            wdata_reg <= 0;
            wstrb_reg <= 0;
            wlast_reg <= 0;
            awid_reg <= 0;
            awaddr_reg <= 0;
            awsize_reg <= 0;
            awburst_reg <= 0;
            awlock_reg <= 0;
            awcache_reg <= 0;
            awprot_reg <= 0;
            awqos_reg <= 0;
            awvalid_reg <= 0;
            awready_reg <= 0;
            wvalid_reg <= 0;
            wready_reg <= 0;
            wlast_reg_int <= 0;
            bvalid_reg <= 0;
            bready_reg <= 0;
            arvalid_reg <= 0;
            arready_reg <= 0;
            arid_reg <= 0;
            araddr_reg <= 0;
            arsize_reg <= 0;
            arbust_reg <= 0;
            arlock_reg <= 0;
            arcache_reg <= 0;
            arprot_reg <= 0;
            arqos_reg <= 0;
            rvalid_reg <= 0;
            rready_reg <= 0;
            rid_reg_int <= 0;
            rdata_reg_int <= 0;
            rlast_reg_int <= 0;
            rresp_reg_int <= 0;
            rdata_fifo_ptr <= 0;
            rstrb_fifo_ptr <= 0;
            rdata_fifo_count <= 0;
            rdata_wr_en <= 0;
            rdata_rd_en <= 0;
            rdata_out <= 0;
            rresp_out <= 0;
            rlast_out <= 0;
            rid_out <= 0;
            wdata_out <= 0;
            wstrb_out <= 0;
            wlast_out <= 0;
            awid_out <= 0;
            awaddr_out <= 0;
            awsize_out <= 0;
            awburst_out <= 0;
            awlock_out <= 0;
            awcache_out <= 0;
            awprot_out <= 0;
            awqos_out <= 0;
            awvalid_out <= 0;
            awready_out <= 0;
            wvalid_out <= 0;
            wready_out <= 0;
            wlast_out_int <= 0;
            bvalid_out <= 0;
            bready_out <= 0;
            arvalid_out <= 0;
            arready_out <= 0;
            arid_out <= 0;
            araddr_out <= 0;
            arsize_out <= 0;
            arbust_out <= 0;
            arlock_out <= 0;
            arcache_out <= 0;
            arprot_out <= 0;
            arqos_out <= 0;
            rvalid_out <= 0;
            rready_out <= 0;
            rid_out_int <= 0;
            rdata_out_int <= 0;
            rlast_out_int <= 0;
            rresp_out_int <= 0;
        end else begin
            current_state <= next_state;
            o_int <= 1'b0;
        end
    end

    // Next State Logic
    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (S_AXIL_AWVALID && S_AXIL_AWREADY) begin
                    next_state = AW_PREPARE;
                end
            end
            AW_PREPARE: begin
                if (S_AXIL_WVALID && S_AXIL_WREADY) begin
                    next_state = W_PREPARE;
                end else if (S_AXIL_ARVALID && S_AXIL_ARREADY) begin
                    next_state = AR_PREPARE;
                end
            end
            AW_SEND: begin
                if (M_AXI_AWREADY) begin
                    next_state = AW_WAIT;
                end
            end
            AW_WAIT: begin
                if (M_AXI_WVALID && M_AXI_WREADY) begin
                    next_state = W_SEND;
                end
            end
            W_SEND: begin
                if (M_AXI_WLAST && M_AXI_BREADY) begin
                    next_state = B_WAIT;
                end
            end
            B_WAIT: begin
                if (M_AXI_BVALID) begin
                    next_state = IDLE;
                end
            end
            AR_PREPARE: begin
                if (S_AXIL_RVALID && S_AXIL_RREADY) begin
                    next_state = R_PREPARE;
                end
            end
            AR_SEND: begin
                if (M_AXI_ARREADY) begin
                    next_state = AR_WAIT;
                end
            end
            AR_WAIT: begin
                if (M_AXI_RVALID && M_AXI_RREADY) begin
                    next_state = R_SEND;
                end
            end
            R_SEND: begin
                if (M_AXI_RLAST && M_AXI_BREADY) begin
                    next_state = B_WAIT;
                end
            end
            R_WAIT: begin
                if (M_AXI_BVALID) begin
                    next_state = IDLE;
                end
            end
            default: next_state = IDLE;
        endcase
    end

    // AW Channel Logic
    always @(*) begin
        M_AXI_AWVALID = (current_state == AW_SEND);
        M_AXI_AWID = awid_reg;
        M_AXI_AWADDR = awaddr_reg;
        M_AXI_AWSIZE = awsize_reg;
        M_AXI_AWBURST = awburst_reg;
        M_AXI_AWLOCK = awlock_reg;
        M_AXI_AWCACHE = awcache_reg;
        M_AXI_AWPROT = awprot_reg;
        M_AXI_AWQOS = awqos_reg;
        M_AXI_WVALID = (current_state == W_SEND);
        M_AXI_WDATA = wdata_reg;
        M_AXI_WSTRB = wstrb_reg;
        M_AXI_WLAST = wlast_reg;
        M_AXI_BREADY = (current_state == B_WAIT);
        M_AXI_ARVALID = (current_state == AR_SEND);
        M_AXI_ARID = arid_reg;
        M_AXI_ARADDR = araddr_reg;
        M_AXI_ARSIZE = arsize_reg;
        M_AXI_ARBURST = arbust_reg;
        M_AXI_ARLOCK = arlock_reg;
        M_AXI_ARCACHE = arcache_reg;
        M_AXI_ARPROT = arprot_reg;
        M_AXI_ARQOS = arqos_reg;
        M_AXI_RREADY = (current_state == R_WAIT);
    end

    // AW Register Updates
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            awid_reg <= AXI_WRITE_ID;
            awaddr_reg <= S_AXIL_AWADDR;
            awsize_reg <= 3'b000;
            awburst_reg <= 2'b00;
            awlock_reg <= 1'b0;
            awcache_reg <= 4'b0000;
            awprot_reg <= S_AXIL_AWPROT;
            awqos_reg <= 4'b0000;
        end else begin
            if (current_state == AW_SEND && M_AXI_AWREADY) begin
                awid_reg <= AXI_WRITE_ID;
                awaddr_reg <= S_AXIL_AWADDR;
                awsize_reg <= 3'b000;
                awburst_reg <= 2'b00;
                awlock_reg <= 1'b0;
                awcache_reg <= 4'b0000;
                awprot_reg <= S_AXIL_AWPROT;
                awqos_reg <= 4'b0000;
            end
        end
    end

    // W Channel Logic
    always @(*) begin
        M_AXI_WDATA = wdata_reg;
        M_AXI_WSTRB = wstrb_reg;
        M_AXI_WLAST = wlast_reg;
    end

    // W Register Updates
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            wdata_reg <= 0;
            wstrb_reg <= 0;
            wlast_reg <= 0;
        end else begin
            if (current_state == W_SEND && M_AXI_WREADY) begin
                wdata_reg <= S_AXIL_WDATA;
                wstrb_reg <= S_AXIL_WSTRB;
                wlast_reg <= 1'b0;
            end
            if (current_state == W_SEND && M_AXI_WLAST && M_AXI_BREADY) begin
                wlast_reg <= 1'b1;
            end
        end
    end

    // AR Channel Logic
    always @(*) begin
        M_AXI_ARID = arid_reg;
        M_AXI_ARADDR = araddr_reg;
        M_AXI_ARSIZE = arsize_reg;
        M_AXI_ARBURST = arbust_reg;
        M_AXI_ARLOCK = arlock_reg;
        M_AXI_ARCACHE = arcache_reg;
        M_AXI_ARPROT = arprot_reg;
        M_AXI_ARQOS = arqos_reg;
    end

    // AR Register Updates
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            arid_reg <= AXI_READ_ID;
            araddr_reg <= 0;
            arsize_reg <= 3'b000;
            arbust_reg <= 2'b00;
            arlock_reg <= 1'b0;
            arcache_reg <= 4'b0000;
            arprot_reg <= 0;
            arqos_reg <= 4'b0000;
        end else begin
            if (current_state == AR_SEND && M_AXI_ARREADY) begin
                arid_reg <= AXI_READ_ID;
                araddr_reg <= S_AXIL_ARADDR;
                arsize_reg <= 3'b000;
                arbust_reg <= 2'b00;
                arlock_reg <= 1'b0;
                arcache_reg <= 4'b0000;
                arprot_reg <= S_AXIL_ARPROT;
                arqos_reg <= 4'b0000;
            end
        end
    end

    // R Channel Logic
    always @(*) begin
        M_AXI_RREADY = rready_reg;
    end

    // R Register Updates
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            rready_reg <= 1'b0;
        end else begin
            if (current_state == R_WAIT && M_AXI_RVALID) begin
                rready_reg <= 1'b1;
            end
        end
    end

    // B Channel Logic
    always @(*) begin
        M_AXI_BREADY = bready_reg;
    end

    // B Register Updates
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            bready_reg <= 1'b0;
        end else begin
            if (current_state == B_WAIT) begin
                bready_reg <= 1'b1;
            end
            if (current_state == B_WAIT && M_AXI_BVALID) begin
                bready_reg <= 1'b0;
            end
        end
    end

    // AXI-Lite Response Logic
    always @(*) begin
        S_AXIL_BVALID = (current_state == B_WAIT && M_AXI_BVALID);
        S_AXIL_BREADY = bready_reg;
        S_AXIL_BRESP = bresp;
        S_AXIL_RVALID = (current_state == R_WAIT && M_AXI_RVALID);
        S_AXIL_RREADY = rready_reg;
        S_AXIL_RDATA = rdata_reg;
        S_AXIL_RRESP = rresp_reg;
    end

    // AXI-Lite Address and Data Logic
    always @(*) begin
        S_AXIL_AWREADY = (current_state == AW_PREPARE);
        S_AXIL_WREADY = (current_state == W_PREPARE);
        S_AXIL_ARREADY = (current_state == AR_PREPARE);
    end

    // State Machine Transitions for Data Transfer
    always @(*) begin
        case (current_state)
            IDLE: begin
                if (S_AXIL_AWVALID && S_AXIL_AWREADY) begin
                    next_state = AW_PREPARE;
                    // Initialize transfer parameters
                    src_addr = S_AXIL_AWADDR;
                    dst_addr = 0;
                    src_len = 0;
                    dst_len = 0;
                    burst_len = 0;
                    burst_type = 0;
                    size = 0;
                    qos = 0;
                    prot = S_AXIL_AWPROT;
                    id = AXI_WRITE_ID;
                    wstrb = 0;
                    wdata = 0;
                    wlast = 0;
                    arlast = 0;
                    rdata = 0;
                    rresp = 0;
                    bid = 0;
                    last_addr = 0;
                    current_addr = 0;
                    remaining_len = 0;
                    total_len = 0;
                    burst_count = 0;
                    burst_remain = 0;
                    fifo_wptr = 0;
                    fifo_rptr = 0;
                    fifo_count = 0;
                    rdata_reg = 0;
                    rresp_reg = 0;
                    rlast_reg = 0;
                    rid_reg = 0;
                    wdata_reg = 0;
                    wstrb_reg = 0;
                    wlast_reg = 0;
                    awid_reg = AXI_WRITE_ID;
                    awaddr_reg = S_AXIL_AWADDR;
                    awsize_reg = 3'b000;
                    awburst_reg = 2'b00;
                    awlock_reg = 1'b0;
                    awcache_reg = 4'b0000;
                    awprot_reg = S_AXIL_AWPROT;
                    awqos_reg = 4'b0000;
                    awvalid_reg = 0;
                    awready_reg = 0;
                    wvalid_reg = 0;
                    wready_reg = 0;
                    wlast_reg_int = 0;
                    bvalid_reg = 0;
                    bready_reg = 0;
                    arvalid_reg = 0;
                    arready_reg = 0;
                    arid_reg = AXI_READ_ID;
                    araddr_reg = 0;
                    arsize_reg = 3'b000;
                    arbust_reg = 2'b00;
                    arlock_reg = 1'b0;
                    arcache_reg = 4'b0000;
                    arprot_reg = 0;
                    arqos_reg = 4'b0000;
                    rvalid_reg = 0;
                    rready_reg = 0;
                    rid_reg_int = 0;
                    rdata_reg_int = 0;
                    rlast_reg_int = 0;
                    rresp_reg_int = 0;
                    rdata_fifo_ptr = 0;
                    rstrb_fifo_ptr = 0;
                    rdata_fifo_count = 0;
                    rdata_wr_en = 0;
                    rdata_rd_en = 0;
                    rdata_out = 0;
                    rresp_out = 0;
                    rlast_out = 0;
                    rid_out = 0;
                    wdata_out = 0;
                    wstrb_out = 0;
                    wlast_out = 0;
                    awid_out = AXI_WRITE_ID;
                    awaddr_out = S_AXIL_AWADDR;
                    awsize_out = 3'b000;
                    awburst_out = 2'b00;
                    awlock_out = 1'b0;
                    awcache_out = 4'b0000;
                    awprot_out = S_AXIL_AWPROT;
                    awqos_out = 4'b0000;
                    awvalid_out = 0;
                    awready_out = 0;
                    wvalid_out = 0;
                    wready_out = 0;
                    wlast_out_int = 0;
                    bvalid_out = 0;
                    bready_out = 0;
                    arvalid_out = 0;
                    arready_out = 0;
                    arid_out = AXI_READ_ID;
                    araddr_out = 0;
                    arsize_out = 3'b000;
                    arbust_out = 2'b00;
                    arlock_out = 1'b0;
                    arcache_out = 4'b0000;
                    arprot_out = 0;
                    arqos_out = 4'b0000;
                    rvalid_out = 0;
                    rready_out = 0;
                    rid_out_int = 0;
                    rdata_out_int = 0;
                    rlast_out_int = 0;
                    rresp_out_int = 0;
                end
            end
            AW_PREPARE: begin
                if (S_AXIL_WVALID && S_AXIL_WREADY) begin
                    next_state = W_PREPARE;
                    // Copy W data to internal registers
                    wdata_reg = S_AXIL_WDATA;
                    wstrb_reg = S_AXIL_WSTRB;
                    wlast_reg = 1'b0;
                end else if (S_AXIL_ARVALID && S_AXIL_ARREADY) begin
                    next_state = AR_PREPARE;
                    // Copy AR data to internal registers
                    arid_reg = AXI_READ_ID;
                    araddr_reg = S_AXIL_ARADDR;
                    arsize_reg = 3'b000;
                    arbust_reg = 2'b00;
                    arlock_reg = 1'b0;
                    arcache_reg = 4'b0000;
                    arprot_reg = S_AXIL_ARPROT;
                    arqos_reg = 4'b0000;
                end
            end
            W_PREPARE: begin
                if (S_AXIL_RVALID && S_AXIL_RREADY) begin
                    next_state = R_PREPARE;
                    // Copy R data to internal registers
                    rdata_reg = S_AXIL_RDATA;
                    rresp_reg = S_AXIL_RRESP;
                    rlast_reg = 1'b0;
                end
            end
            AR_PREPARE: begin
                if (S_AXIL_RVALID && S_AXIL_RREADY) begin
                    next_state = R_PREPARE;
                    // Copy R data to internal registers
                    rdata_reg = S_AXIL_RDATA;
                    rresp_reg = S_AXIL_RRESP;
                    rlast_reg = 1'b0;
                end
            end
            default: next_state = IDLE;
        endcase
    end

    // AXI Master Interface Logic
    always @(*) begin
        M_AXI_AWVALID = awvalid_reg;
        M_AXI_AWID = awid_out;
        M_AXI_AWADDR = awaddr_out;
        M_AXI_AWSIZE = awsize_out;
        M_AXI_AWBURST = awburst_out;
        M_AXI_AWLOCK = awlock_out;
        M_AXI_AWCACHE = awcache_out;
        M_AXI_AWPROT = awprot_out;
        M_AXI_AWQOS = awqos_out;
        M_AXI_WVALID = wvalid_out;
        M_AXI_WDATA = wdata_out;
        M_AXI_WSTRB = wstrb_out;
        M_AXI_WLAST = wlast_out_int;
        M_AXI_BREADY = bready_out;
        M_AXI_ARVALID = arvalid_out;
        M_AXI_ARID = arid_out;
        M_AXI_ARADDR = araddr_out;
        M_AXI_ARSIZE = arsize_out;
        M_AXI_ARBURST = arbust_out;
        M_AXI_ARLOCK = arlock_out;
        M_AXI_ARCACHE = arcache_out;
        M_AXI_ARPROT = arprot_out;
        M_AXI_ARQOS = arqos_out;
        M_AXI_RREADY = rready_out;
    end

    // AXI Master Interface Registers
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            awvalid_reg <= 0;
            awready_reg <= 0;
            wvalid_reg <= 0;
            wready_reg <= 0;
            wlast_reg_int <= 0;
            bvalid_reg <= 0;
            bready_reg <= 0;
            arvalid_reg <= 0;
            arready_reg <= 0;
            arid_reg <= AXI_READ_ID;
            araddr_reg <= 0;
            arsize_reg <= 3'b000;
            arbust_reg <= 2'b00;
            arlock_reg <= 1'b0;
            arcache_reg <= 4'b0000;
            arprot_reg <= 0;
            arqos_reg <= 4'b0000;
            rvalid_reg <= 0;
            rready_reg <= 0;
            rid_reg_int <= 0;
            rdata_reg_int <= 0;
            rlast_reg_int <= 0;
            rresp_reg_int <= 0;
            rdata_fifo_ptr <= 0;
            rstrb_fifo_ptr <= 0;
            rdata_fifo_count <= 0;
            rdata_wr_en <= 0;
            rdata_rd_en <= 0;
            rdata_out <= 0;
            rresp_out <= 0;
            rlast_out <= 0;
            rid_out <= 0;
            wdata_out <= 0;
            wstrb_out <= 0;
            wlast_out <= 0;
            awid_out <= AXI_WRITE_ID;
            awaddr_out <= 0;
            awsize_out <= 3'b000;
            awburst_out <= 2'b00;
            awlock_out <= 1'b0;
            awcache_out <= 4'b0000;
            awprot_out <= 0;
            awqos_out <= 4'b0000;
            awvalid_out <= 0;
            aw