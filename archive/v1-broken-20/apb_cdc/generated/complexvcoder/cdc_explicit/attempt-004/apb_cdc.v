module apb_cdc #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      src_pclk_i,
    input                      src_preset_ni,
    input                      src_psel_i,
    input                      src_penable_i,
    input                      src_pwrite_i,
    input  [ADDR_WIDTH-1:0]    src_paddr_i,
    input  [DATA_WIDTH-1:0]    src_pwdata_i,
    input  [DATA_WIDTH/8-1:0]  src_pstrb_i,
    input  [2:0]               src_pprot_i,
    output                     src_pready_o,
    output [DATA_WIDTH-1:0]    src_prdata_o,
    output                     src_pslverr_o,
    input                      dst_pclk_i,
    input                      dst_preset_ni,
    output                     dst_psel_o,
    output                     dst_penable_o,
    output                     dst_pwrite_o,
    output [ADDR_WIDTH-1:0]    dst_paddr_o,
    output [DATA_WIDTH-1:0]    dst_pwdata_o,
    output [DATA_WIDTH/8-1:0]  dst_pstrb_o,
    output [2:0]               dst_pprot_o,
    input                      dst_pready_i,
    input  [DATA_WIDTH-1:0]    dst_prdata_i,
    input                      dst_pslverr_i
);

    // Internal signals
    logic [DATA_WIDTH-1:0] src_data_out;
    logic src_valid_out;
    logic src_ready_in;
    logic [DATA_WIDTH-1:0] dst_data_in;
    logic dst_valid_in;
    logic dst_ready_out;
    logic [2:0] dst_pprot_in;
    logic [DATA_WIDTH/8-1:0] dst_pstrb_in;

    // APB Master
    apb_master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) apb_master_inst (
        .pclk_i(src_pclk_i),
        .preset_ni(src_preset_ni),
        .psel_i(src_psel_i),
        .penable_i(src_penable_i),
        .pwrite_i(src_pwrite_i),
        .paddr_i(src_paddr_i),
        .pwdata_i(src_pwdata_i),
        .pstrb_i(src_pstrb_i),
        .pprot_i(src_pprot_i),
        .pready_o(src_ready_in),
        .prdata_o(src_data_out),
        .pslverr_o(src_pslverr_o)
    );

    // FIFOs
    fifos #(
        .DATA_WIDTH(DATA_WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifos_inst (
        .clk(src_pclk_i),
        .rst_ni(src_preset_ni),
        .master_ready_i(src_ready_in),
        .master_data_i(src_data_out),
        .master_error_i(src_pslverr_o),
        .slave_ready_o(dst_ready_out),
        .slave_data_o(dst_data_in),
        .slave_error_o(src_pslverr_o)
    );

    // APB Slave
    apb_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) apb_slave_inst (
        .pclk_i(dst_pclk_i),
        .preset_ni(dst_preset_ni),
        .pready_i(dst_pready_i),
        .prdata_i(dst_prdata_i),
        .pslverr_i(dst_pslverr_i),
        .psel_o(dst_psel_o),
        .penable_o(dst_penable_o),
        .pwrite_o(dst_pwrite_o),
        .paddr_o(dst_paddr_o),
        .pwdata_o(dst_pwdata_o),
        .pstrb_o(dst_pstrb_o),
        .pprot_o(dst_pprot_in)
    );

    // Handshake between master and slave
    assign src_pready_o = dst_ready_out;

    // Drive destination signals
    assign dst_pprot_in = src_pprot_i;
    assign dst_pstrb_in = src_pstrb_i;
    assign dst_pwdata_in = src_pwdata_i;

endmodule

module apb_master #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32
)(
    input                      pclk_i,
    input                      preset_ni,
    input                      psel_i,
    input                      penable_i,
    input                      pwrite_i,
    input  [ADDR_WIDTH-1:0]    paddr_i,
    input  [DATA_WIDTH-1:0]    pwdata_i,
    input  [DATA_WIDTH/8-1:0]  pstrb_i,
    input  [2:0]               pprot_i,
    output                     pready_o,
    output [DATA_WIDTH-1:0]    prdata_o,
    output                     pslverr_o
);

    // Internal signals
    logic [DATA_WIDTH-1:0] data_reg;
    logic [2:0] prot_reg;
    logic [DATA_WIDTH/8-1:0] strb_reg;
    logic ready_reg;

    // Register the inputs
    always_ff @(posedge pclk_i or negedge preset_ni) begin
        if (!preset_ni) begin
            data_reg <= 0;
            prot_reg <= 0;
            strb_reg <= 0;
            ready_reg <= 0;
        end else begin
            if (psel_i && penable_i) begin
                data_reg <= pwdata_i;
                prot_reg <= pprot_i;
                strb_reg <= pstrb_i;
                ready_reg <= pwrite_i;
            end
        end
    end

    // Drive outputs
    assign prdata_o = data_reg;
    assign pslverr_o = 0;

    // Drive pready_o
    assign pready_o = ready_reg;

endmodule

module apb_slave #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32
)(
    input                      pclk_i,
    input                      preset_ni,
    input                      pready_i,
    input  [DATA_WIDTH-1:0]    prdata_i,
    input                      pslverr_i,
    output                     psel_o,
    output                     penable_o,
    output                     pwrite_o,
    output [ADDR_WIDTH-1:0]    paddr_o,
    output [DATA_WIDTH-1:0]    pwdata_o,
    output [DATA_WIDTH/8-1:0]  pstrb_o,
    output [2:0]               pprot_o
);

    // Internal signals
    logic psel_reg;
    logic penable_reg;
    logic pwrite_reg;
    logic [ADDR_WIDTH-1:0] paddr_reg;
    logic [DATA_WIDTH-1:0] pwdata_reg;
    logic [DATA_WIDTH/8-1:0] pstrb_reg;
    logic [2:0] pprot_reg;

    // Register the inputs
    always_ff @(posedge pclk_i or negedge preset_ni) begin
        if (!preset_ni) begin
            psel_reg <= 0;
            penable_reg <= 0;
            pwrite_reg <= 0;
            paddr_reg <= 0;
            pwdata_reg <= 0;
            pstrb_reg <= 0;
            pprot_reg <= 0;
        end else begin
            if (pready_i) begin
                psel_reg <= 1;
                penable_reg <= 1;
                pwrite_reg <= 0;
                paddr_reg <= 0;
                pwdata_reg <= prdata_i;
                pstrb_reg <= (1 << DATA_WIDTH/8) - 1;
                pprot_reg <= 0;
            end else begin
                psel_reg <= 0;
                penable_reg <= 0;
                pwrite_reg <= 0;
                paddr_reg <= 0;
                pwdata_reg <= 0;
                pstrb_reg <= 0;
                pprot_reg <= 0;
            end
        end
    end

    // Drive outputs
    assign psel_o = psel_reg;
    assign penable_o = penable_reg;
    assign pwrite_o = pwrite_reg;
    assign paddr_o = paddr_reg;
    assign pwdata_o = pwdata_reg;
    assign pstrb_o = pstrb_reg;
    assign pprot_o = pprot_reg;

endmodule

module fifos #(
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      clk,
    input                      rst_ni,
    input                      master_ready_i,
    input  [DATA_WIDTH-1:0]    master_data_i,
    input                      master_error_i,
    output                     slave_ready_o,
    output [DATA_WIDTH-1:0]    slave_data_o,
    output                     slave_error_o
);

    // Internal signals
    logic [DATA_WIDTH-1:0] mem [0:2**LOG_DEPTH-1];
    logic [LOG_DEPTH:0] wr_ptr;
    logic [LOG_DEPTH:0] rd_ptr;
    logic [LOG_DEPTH:0] count;

    // Write operation
    always_ff @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            wr_ptr <= 0;
        end else if (master_ready_i && wr_ptr < 2**LOG_DEPTH) begin
            mem[wr_ptr] <= master_data_i;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read operation
    always_ff @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            rd_ptr <= 0;
        end else if (count > 0 && rd_ptr < 2**LOG_DEPTH) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Count the number of valid entries
    always_ff @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            count <= 0;
        end else begin
            count <= wr_ptr - rd_ptr;
        end
    end

    // Output signals
    assign slave_ready_o = (count < 2**LOG_DEPTH);
    assign slave_data_o = mem[rd_ptr];
    assign slave_error_o = master_error_i;

endmodule
