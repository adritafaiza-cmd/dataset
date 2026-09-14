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
    reg [ADDR_WIDTH-1:0] src_addr_reg;
    reg [DATA_WIDTH-1:0] src_data_reg;
    reg [DATA_WIDTH/8-1:0] src_strb_reg;
    reg [2:0] src_prot_reg;
    reg src_write_reg;
    reg src_psel_reg;
    reg src_penable_reg;
    reg src_pready_reg;
    reg src_prdata_reg;
    reg src_pslverr_reg;

    reg dst_addr_reg;
    reg dst_data_reg;
    reg dst_write_reg;
    reg dst_psel_reg;
    reg dst_penable_reg;
    reg dst_pready_reg;
    reg dst_prdata_reg;
    reg dst_pslverr_reg;

    // FIFOs
    wire [DATA_WIDTH-1:0] src_to_dst_fifo_in;
    wire src_to_dst_fifo_valid_in;
    wire src_to_dst_fifo_ready_out;
    wire [DATA_WIDTH-1:0] src_to_dst_fifo_out;
    wire src_to_dst_fifo_valid_out;
    wire src_to_dst_fifo_ready_in;

    wire [DATA_WIDTH-1:0] dst_to_src_fifo_in;
    wire dst_to_src_fifo_valid_in;
    wire dst_to_src_fifo_ready_out;
    wire [DATA_WIDTH-1:0] dst_to_src_fifo_out;
    wire dst_to_src_fifo_valid_out;
    wire dst_to_src_fifo_ready_in;

    // FIFO instances
    fifo #(.WIDTH(DATA_WIDTH), .LOG_DEPTH(LOG_DEPTH)) src_to_dst_fifo (
        .clk(src_pclk_i),
        .rst_n(src_preset_ni),
        .in(src_pwdata_i),
        .valid_in(src_penable_i),
        .ready_out(src_pready_o),
        .out(src_to_dst_fifo_out),
        .valid_out(src_to_dst_fifo_valid_out),
        .ready_in(src_to_dst_fifo_ready_in)
    );

    fifo #(.WIDTH(DATA_WIDTH), .LOG_DEPTH(LOG_DEPTH)) dst_to_src_fifo (
        .clk(dst_pclk_i),
        .rst_n(dst_preset_ni),
        .in(dst_prdata_i),
        .valid_in(dst_pready_i),
        .ready_out(dst_pready_o),
        .out(dst_to_src_fifo_out),
        .valid_out(dst_to_src_fifo_valid_out),
        .ready_in(dst_to_src_fifo_ready_in)
    );

    // Register for source interface
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_addr_reg <= 0;
            src_data_reg <= 0;
            src_strb_reg <= 0;
            src_prot_reg <= 0;
            src_write_reg <= 0;
            src_psel_reg <= 0;
            src_penable_reg <= 0;
            src_pready_reg <= 0;
            src_prdata_reg <= 0;
            src_pslverr_reg <= 0;
        end else begin
            if (src_psel_i && src_penable_i) begin
                src_addr_reg <= src_paddr_i;
                src_data_reg <= src_pwdata_i;
                src_strb_reg <= src_pstrb_i;
                src_prot_reg <= src_pprot_i;
                src_write_reg <= src_pwrite_i;
                src_psel_reg <= src_psel_i;
                src_penable_reg <= src_penable_i;
                src_pready_reg <= src_pready_o;
                src_prdata_reg <= src_prdata_o;
                src_pslverr_reg <= src_pslverr_o;
            end
        end
    end

    // Register for destination interface
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_addr_reg <= 0;
            dst_data_reg <= 0;
            dst_write_reg <= 0;
            dst_psel_reg <= 0;
            dst_penable_reg <= 0;
            dst_pready_reg <= 0;
            dst_prdata_reg <= 0;
            dst_pslverr_reg <= 0;
        end else begin
            if (dst_psel_o && dst_penable_o) begin
                dst_addr_reg <= src_addr_reg;
                dst_data_reg <= src_data_reg;
                dst_write_reg <= src_write_reg;
                dst_psel_reg <= src_psel_reg;
                dst_penable_reg <= src_penable_reg;
                dst_pready_reg <= src_pready_reg;
                dst_prdata_reg <= src_prdata_reg;
                dst_pslverr_reg <= src_pslverr_reg;
            end
        end
    end

    // Connect FIFOs to destination interface
    assign dst_psel_o = src_psel_reg;
    assign dst_penable_o = src_penable_reg;
    assign dst_pwrite_o = src_write_reg;
    assign dst_paddr_o = src_addr_reg;
    assign dst_pwdata_o = src_data_reg;
    assign dst_pstrb_o = src_strb_reg;
    assign dst_pprot_o = src_prot_reg;

    // Connect FIFOs to source interface
    assign src_pready_o = src_to_dst_fifo_ready_out;
    assign src_prdata_o = src_to_dst_fifo_out;
    assign src_pslverr_o = src_to_dst_fifo_valid_out ? dst_pslverr_reg : 0;

endmodule
