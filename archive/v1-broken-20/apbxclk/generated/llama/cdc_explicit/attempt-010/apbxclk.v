module apbxclk #(
    parameter C_APB_ADDR_WIDTH = 12,
    parameter C_APB_DATA_WIDTH = 32,
    parameter [0:0] OPT_REGISTERED = 1'b0,
    localparam AW = C_APB_ADDR_WIDTH,
    localparam DW = C_APB_DATA_WIDTH
) (
    input wire S_APB_PCLK, S_PRESETn,
    input wire S_APB_PSEL,
    input wire S_APB_PENABLE,
    output reg S_APB_PREADY,
    input wire [AW-1:0] S_APB_PADDR,
    input wire S_APB_PWRITE,
    input wire [DW-1:0] S_APB_PWDATA,
    input wire [DW/8-1:0] S_APB_PWSTRB,
    input wire [2:0] S_APB_PPROT,
    output wire [DW-1:0] S_APB_PRDATA,
    output wire S_APB_PSLVERR,
    input wire M_APB_PCLK,
    output reg M_PRESETn,
    output reg M_APB_PSEL,
    output reg M_APB_PENABLE,
    input wire M_APB_PREADY,
    output wire [AW-1:0] M_APB_PADDR,
    output wire M_APB_PWRITE,
    output wire [DW-1:0] M_APB_PWDATA,
    output wire [DW/8-1:0] M_APB_PWSTRB,
    output wire [2:0] M_APB_PPROT,
    input wire [DW-1:0] M_APB_PRDATA,
    input wire M_APB_PSLVERR
);

    reg [AW-1:0] addr;
    reg [DW-1:0] wdata;
    reg [DW/8-1:0] wstrb;
    reg [2:0] prot;
    reg write;
    reg valid;
    reg [DW-1:0] rdata;
    reg rslverr;

    reg [1:0] state;
    localparam IDLE = 2'd0;
    localparam SEND = 2'd1;
    localparam WAIT = 2'd2;

    reg [AW-1:0] s_addr;
    reg [DW-1:0] s_wdata;
    reg [DW/8-1:0] s_wstrb;
    reg [2:0] s_prot;
    reg s_write;
    reg [DW-1:0] s_rdata;
    reg s_rslverr;

    always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            state <= IDLE;
            valid <= 1'b0;
            S_APB_PREADY <= 1'b0;
            M_PRESETn <= 1'b0;
            M_APB_PSEL <= 1'b0;
            M_APB_PENABLE <= 1'b0;
        end else if (state == IDLE) begin
            if (S_APB_PSEL && S_APB_PENABLE) begin
                state <= SEND;
                valid <= 1'b1;
                addr <= S_APB_PADDR;
                wdata <= S_APB_PWDATA;
                wstrb <= S_APB_PWSTRB;
                prot <= S_APB_PPROT;
                write <= S_APB_PWRITE;
            end
        end else if (state == SEND) begin
            M_PRESETn <= 1'b1;
            M_APB_PSEL <= 1'b1;
            M_APB_PADDR <= addr;
            M_APB_PWRITE <= write;
            M_APB_PWDATA <= wdata;
            M_APB_PWSTRB <= wstrb;
            M_APB_PPROT <= prot;
            state <= WAIT;
        end else if (state == WAIT) begin
            if (M_APB_PREADY) begin
                state <= IDLE;
                valid <= 1'b0;
                S_APB_PREADY <= 1'b1;
                s_addr <= addr;
                s_wdata <= wdata;
                s_wstrb <= wstrb;
                s_prot <= prot;
                s_write <= write;
                s_rdata <= M_APB_PRDATA;
                s_rslverr <= M_APB_PSLVERR;
                M_APB_PSEL <= 1'b0;
                M_APB_PENABLE <= 1'b0;
            end
        end
    end

    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            M_APB_PENABLE <= 1'b0;
        end else if (state == WAIT) begin
            M_APB_PENABLE <= 1'b1;
        end else begin
            M_APB_PENABLE <= 1'b0;
        end
    end

    assign S_APB_PRDATA = s_rdata;
    assign S_APB_PSLVERR = s_rslverr;

    // CDC
    reg [DW-1:0] rdata_sync;
    reg rslverr_sync;
    reg [AW-1:0] addr_sync;
    reg [DW-1:0] wdata_sync;
    reg [DW/8-1:0] wstrb_sync;
    reg [2:0] prot_sync;
    reg write_sync;

    always @(posedge M_APB_PCLK or negedge S_PRESETn) begin
        if (!S_PRESETn) begin
            rdata_sync <= {DW{1'b0}};
            rslverr_sync <= 1'b0;
            addr_sync <= {AW{1'b0}};
            wdata_sync <= {DW{1'b0}};
            wstrb_sync <= {DW/8{1'b0}};
            prot_sync <= {3{1'b0}};
            write_sync <= 1'b0;
        end else begin
            rdata_sync <= s_rdata;
            rslverr_sync <= s_rslverr;
            addr_sync <= s_addr;
            wdata_sync <= s_wdata;
            wstrb_sync <= s_wstrb;
            prot_sync <= s_prot;
            write_sync <= s_write;
        end
    end

    assign S_APB_PRDATA = rdata_sync;
    assign S_APB_PSLVERR = rslverr_sync;

    // Registered option
    if (OPT_REGISTERED) begin
        reg [AW-1:0] addr_reg;
        reg [DW-1:0] wdata_reg;
        reg [DW/8-1:0] wstrb_reg;
        reg [2:0] prot_reg;
        reg write_reg;
        reg [DW-1:0] rdata_reg;
        reg rslverr_reg;

        always @(posedge S_APB_PCLK or negedge S_PRESETn) begin
            if (!S_PRESETn) begin
                addr_reg <= {AW{1'b0}};
                wdata_reg <= {DW{1'b0}};
                wstrb_reg <= {DW/8{1'b0}};
                prot_reg <= {3{1'b0}};
                write_reg <= 1'b0;
                rdata_reg <= {DW{1'b0}};
                rslverr_reg <= 1'b0;
            end else if (state == SEND) begin
                addr_reg <= addr;
                wdata_reg <= wdata;
                wstrb_reg <= wstrb;
                prot_reg <= prot;
                write_reg <= write;
            end else if (state == WAIT) begin
                rdata_reg <= M_APB_PRDATA;
                rslverr_reg <= M_APB_PSLVERR;
            end
        end

        assign M_APB_PADDR = addr_reg;
        assign M_APB_PWRITE = write_reg;
        assign M_APB_PWDATA = wdata_reg;
        assign M_APB_PWSTRB = wstrb_reg;
        assign M_APB_PPROT = prot_reg;
        assign S_APB_PRDATA = rdata_reg;
        assign S_APB_PSLVERR = rslverr_reg;
    end else begin
        assign M_APB_PADDR = addr;
        assign M_APB_PWRITE = write;
        assign M_APB_PWDATA = wdata;
        assign M_APB_PWSTRB = wstrb;
        assign M_APB_PPROT = prot;
    end
endmodule
