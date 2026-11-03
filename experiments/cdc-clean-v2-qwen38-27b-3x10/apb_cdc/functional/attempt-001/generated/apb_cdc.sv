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

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam PTR_W = LOG_DEPTH;

    // Source-side state
    reg src_idle;
    reg src_access;
    reg [DATA_WIDTH-1:0] src_rdata_reg;
    reg src_rslverr_reg;

    // Destination-side state
    reg dst_idle;
    reg dst_setup;
    reg dst_access;
    reg [ADDR_WIDTH-1:0] dst_addr_reg;
    reg [DATA_WIDTH-1:0] dst_wdata_reg;
    reg [DATA_WIDTH/8-1:0] dst_strb_reg;
    reg [2:0] dst_pprot_reg;
    reg dst_write_reg;

    // Handshake signals
    reg src_req_valid;
    reg dst_req_ready;
    reg dst_done_valid;
    reg src_done_ready;

    // Source side: detect APB setup phase completion
    wire src_setup_done = src_psel_i & ~src_penable_i;
    wire src_access_done = src_psel_i & src_penable_i & src_pready_o;

    // Source state machine
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_idle <= 1'b1;
            src_access <= 1'b0;
            src_rdata_reg <= {DATA_WIDTH{1'b0}};
            src_rslverr_reg <= 1'b0;
            src_req_valid <= 1'b0;
            src_done_ready <= 1'b1;
        end else begin
            if (src_idle) begin
                if (src_setup_done) begin
                    src_idle <= 1'b0;
                    src_access <= 1'b1;
                    src_req_valid <= 1'b1;
                    src_done_ready <= 1'b0;
                end
            end else if (src_access) begin
                if (src_done_ready) begin
                    src_idle <= 1'b1;
                    src_access <= 1'b0;
                    src_req_valid <= 1'b0;
                    src_done_ready <= 1'b1;
                end
            end
        end
    end

    // Source outputs
    assign src_pready_o = src_access & src_done_ready;
    assign src_prdata_o = src_rdata_reg;
    assign src_pslverr_o = src_rslverr_reg;

    // Destination side: generate APB signals
    assign dst_psel_o = dst_setup | dst_access;
    assign dst_penable_o = dst_access;
    assign dst_pwrite_o = dst_write_reg;
    assign dst_paddr_o = dst_addr_reg;
    assign dst_pwdata_o = dst_wdata_reg;
    assign dst_pstrb_o = dst_strb_reg;
    assign dst_pprot_o = dst_pprot_reg;

    // Destination state machine
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_idle <= 1'b1;
            dst_setup <= 1'b0;
            dst_access <= 1'b0;
            dst_addr_reg <= {ADDR_WIDTH{1'b0}};
            dst_wdata_reg <= {DATA_WIDTH{1'b0}};
            dst_strb_reg <= {(DATA_WIDTH/8){1'b0}};
            dst_pprot_reg <= 3'b0;
            dst_write_reg <= 1'b0;
            dst_req_ready <= 1'b1;
            dst_done_valid <= 1'b0;
        end else begin
            if (dst_idle) begin
                if (src_req_valid) begin
                    dst_idle <= 1'b0;
                    dst_setup <= 1'b1;
                    dst_access <= 1'b0;
                    dst_req_ready <= 1'b0;
                    dst_done_valid <= 1'b0;
                    // Latch request data
                    dst_addr_reg <= src_paddr_i;
                    dst_wdata_reg <= src_pwdata_i;
                    dst_strb_reg <= src_pstrb_i;
                    dst_pprot_reg <= src_pprot_i;
                    dst_write_reg <= src_pwrite_i;
                end
            end else if (dst_setup) begin
                dst_setup <= 1'b0;
                dst_access <= 1'b1;
            end else if (dst_access) begin
                if (dst_pready_i) begin
                    dst_idle <= 1'b1;
                    dst_setup <= 1'b0;
                    dst_access <= 1'b0;
                    dst_req_ready <= 1'b1;
                    dst_done_valid <= 1'b1;
                end
            end
        end
    end

    // Source side: capture read data and error when destination completes
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_rdata_reg <= {DATA_WIDTH{1'b0}};
            src_rslverr_reg <= 1'b0;
        end else begin
            if (dst_done_valid) begin
                src_rdata_reg <= dst_prdata_i;
                src_rslverr_reg <= dst_pslverr_i;
                src_done_ready <= 1'b1;
            end
        end
    end

endmodule
