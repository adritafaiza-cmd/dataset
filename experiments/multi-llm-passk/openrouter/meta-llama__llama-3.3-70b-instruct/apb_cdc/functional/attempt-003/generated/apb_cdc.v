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

    reg [ADDR_WIDTH-1:0]        fifo_addr [2**LOG_DEPTH-1:0];
    reg [DATA_WIDTH-1:0]        fifo_wdata [2**LOG_DEPTH-1:0];
    reg [DATA_WIDTH/8-1:0]      fifo_wstrb [2**LOG_DEPTH-1:0];
    reg [2:0]                   fifo_wprot [2**LOG_DEPTH-1:0];
    reg                         fifo_write [2**LOG_DEPTH-1:0];
    reg [2**LOG_DEPTH-1:0]      fifo_valid;
    reg [2**LOG_DEPTH-1:0]      fifo_ready;
    reg [2**LOG_DEPTH-1:0]      fifo_empty;
    reg [2**LOG_DEPTH-1:0]      fifo_full;

    reg                         src_req_valid;
    reg                         src_req_ready;
    reg                         dst_req_valid;
    reg                         dst_req_ready;

    reg                         src_pready_int;
    reg [DATA_WIDTH-1:0]        src_prdata_int;
    reg                         src_pslverr_int;

    reg                         dst_psel_int;
    reg                         dst_penable_int;
    reg                         dst_pwrite_int;
    reg [ADDR_WIDTH-1:0]        dst_paddr_int;
    reg [DATA_WIDTH-1:0]        dst_pwdata_int;
    reg [DATA_WIDTH/8-1:0]      dst_pstrb_int;
    reg [2:0]                   dst_pprot_int;

    assign src_pready_o = src_pready_int;
    assign src_prdata_o = src_prdata_int;
    assign src_pslverr_o = src_pslverr_int;

    assign dst_psel_o = dst_psel_int;
    assign dst_penable_o = dst_penable_int;
    assign dst_pwrite_o = dst_pwrite_int;
    assign dst_paddr_o = dst_paddr_int;
    assign dst_pwdata_o = dst_pwdata_int;
    assign dst_pstrb_o = dst_pstrb_int;
    assign dst_pprot_o = dst_pprot_int;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_req_valid <= 1'b0;
            src_pready_int <= 1'b0;
            src_prdata_int <= {DATA_WIDTH{1'b0}};
            src_pslverr_int <= 1'b0;
        end else begin
            if (src_psel_i && src_penable_i) begin
                src_req_valid <= 1'b1;
                src_pready_int <= 1'b0;
            end else if (src_pready_int) begin
                src_req_valid <= 1'b0;
                src_pready_int <= 1'b0;
            end
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_psel_int <= 1'b0;
            dst_penable_int <= 1'b0;
            dst_pwrite_int <= 1'b0;
            dst_paddr_int <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_int <= {DATA_WIDTH{1'b0}};
            dst_pstrb_int <= {DATA_WIDTH/8{1'b0}};
            dst_pprot_int <= {3{1'b0}};
        end else begin
            if (dst_pready_i) begin
                dst_psel_int <= 1'b0;
                dst_penable_int <= 1'b0;
            end else if (dst_req_valid) begin
                dst_psel_int <= 1'b1;
                dst_penable_int <= 1'b1;
            end
        end
    end

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            fifo_valid <= {2**LOG_DEPTH{1'b0}};
            fifo_ready <= {2**LOG_DEPTH{1'b0}};
            fifo_empty <= {2**LOG_DEPTH{1'b1}};
            fifo_full <= {2**LOG_DEPTH{1'b0}};
        end else begin
            if (src_req_valid && !fifo_full[0]) begin
                fifo_addr[0] <= src_paddr_i;
                fifo_wdata[0] <= src_pwdata_i;
                fifo_wstrb[0] <= src_pstrb_i;
                fifo_wprot[0] <= src_pprot_i;
                fifo_write[0] <= src_pwrite_i;
                fifo_valid[0] <= 1'b1;
                fifo_empty[0] <= 1'b0;
            end
            if (dst_pready_i && fifo_valid[0]) begin
                fifo_valid[0] <= 1'b0;
                fifo_empty[0] <= 1'b1;
            end
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_req_valid <= 1'b0;
        end else begin
            if (fifo_valid[0] && !dst_req_valid) begin
                dst_paddr_int <= fifo_addr[0];
                dst_pwdata_int <= fifo_wdata[0];
                dst_pstrb_int <= fifo_wstrb[0];
                dst_pprot_int <= fifo_wprot[0];
                dst_pwrite_int <= fifo_write[0];
                dst_req_valid <= 1'b1;
            end
            if (dst_pready_i && dst_req_valid) begin
                dst_req_valid <= 1'b0;
                src_prdata_int <= dst_prdata_i;
                src_pslverr_int <= dst_pslverr_i;
                src_pready_int <= 1'b1;
            end
        end
    end

endmodule
