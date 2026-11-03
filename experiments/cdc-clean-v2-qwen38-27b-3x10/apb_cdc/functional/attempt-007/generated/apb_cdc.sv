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
    wire [DATA_WIDTH/8-1:0] src_pstrb_w = src_pstrb_i;
    wire [DATA_WIDTH/8-1:0] dst_pstrb_w;

    // Source side state machine
    // States: IDLE, SETUP, ACCESS
    localparam SRC_IDLE   = 2'd0;
    localparam SRC_SETUP  = 2'd1;
    localparam SRC_ACCESS = 2'd2;

    reg [1:0] src_state;
    reg       src_pready_r;
    reg [DATA_WIDTH-1:0] src_prdata_r;
    reg       src_pslverr_r;

    // Request valid signal to destination side
    reg       req_valid_src;
    reg       req_valid_dst;
    reg       req_valid_dst_sync1;
    reg       req_valid_dst_sync2;

    // Data valid signal (for read data return)
    reg       data_valid_src;
    reg       data_valid_dst;
    reg       data_valid_dst_sync1;
    reg       data_valid_dst_sync2;

    // Request data to be sent across CDC
    reg [ADDR_WIDTH-1:0] req_addr_src;
    reg [DATA_WIDTH-1:0] req_wdata_src;
    reg [DATA_WIDTH/8-1:0] req_strb_src;
    reg [2:0] req_pprot_src;
    reg       req_write_src;

    // Destination side state machine
    // States: IDLE, SETUP, ACCESS
    localparam DST_IDLE   = 2'd0;
    localparam DST_SETUP  = 2'd1;
    localparam DST_ACCESS = 2'd2;

    reg [1:0] dst_state;
    reg       dst_psel_r;
    reg       dst_penable_r;
    reg       dst_pwrite_r;
    reg [ADDR_WIDTH-1:0] dst_paddr_r;
    reg [DATA_WIDTH-1:0] dst_pwdata_r;
    reg [DATA_WIDTH/8-1:0] dst_pstrb_r;
    reg [2:0] dst_pprot_r;

    // Read data return path
    reg [DATA_WIDTH-1:0] rdata_dst;
    reg       rslverr_dst;
    reg [DATA_WIDTH-1:0] rdata_src;
    reg       rslverr_src;

    // Synchronizers for request valid
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            req_valid_dst_sync1 <= 1'b0;
            req_valid_dst_sync2 <= 1'b0;
        end else begin
            req_valid_dst_sync1 <= req_valid_src;
            req_valid_dst_sync2 <= req_valid_dst_sync1;
        end
    end

    // Synchronizers for data valid
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            data_valid_dst_sync1 <= 1'b0;
            data_valid_dst_sync2 <= 1'b0;
        end else begin
            data_valid_dst_sync1 <= data_valid_dst;
            data_valid_dst_sync2 <= data_valid_dst_sync1;
        end
    end

    // Source side logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_state <= SRC_IDLE;
            src_pready_r <= 1'b0;
            src_prdata_r <= {DATA_WIDTH{1'b0}};
            src_pslverr_r <= 1'b0;
            req_valid_src <= 1'b0;
            req_addr_src <= {ADDR_WIDTH{1'b0}};
            req_wdata_src <= {DATA_WIDTH{1'b0}};
            req_strb_src <= {(DATA_WIDTH/8){1'b0}};
            req_pprot_src <= 3'b000;
            req_write_src <= 1'b0;
            data_valid_src <= 1'b0;
            rdata_src <= {DATA_WIDTH{1'b0}};
            rslverr_src <= 1'b0;
        end else begin
            case (src_state)
                SRC_IDLE: begin
                    src_pready_r <= 1'b0;
                    if (src_psel_i) begin
                        // Capture request and move to setup
                        req_addr_src <= src_paddr_i;
                        req_wdata_src <= src_pwdata_i;
                        req_strb_src <= src_pstrb_w;
                        req_pprot_src <= src_pprot_i;
                        req_write_src <= src_pwrite_i;
                        req_valid_src <= 1'b1;
                        src_state <= SRC_SETUP;
                    end
                end
                SRC_SETUP: begin
                    src_pready_r <= 1'b0;
                    if (src_penable_i) begin
                        src_state <= SRC_ACCESS;
                    end
                end
                SRC_ACCESS: begin
                    // Wait for data valid from destination
                    if (data_valid_dst_sync2) begin
                        src_prdata_r <= rdata_src;
                        src_pslverr_r <= rslverr_src;
                        src_pready_r <= 1'b1;
                        req_valid_src <= 1'b0;
                        data_valid_src <= 1'b0;
                        src_state <= SRC_IDLE;
                    end
                end
                default: begin
                    src_state <= SRC_IDLE;
                end
            endcase
        end
    end

    // Destination side logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_state <= DST_IDLE;
            dst_psel_r <= 1'b0;
            dst_penable_r <= 1'b0;
            dst_pwrite_r <= 1'b0;
            dst_paddr_r <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_r <= {DATA_WIDTH{1'b0}};
            dst_pstrb_r <= {(DATA_WIDTH/8){1'b0}};
            dst_pprot_r <= 3'b000;
            data_valid_dst <= 1'b0;
            rdata_dst <= {DATA_WIDTH{1'b0}};
            rslverr_dst <= 1'b0;
        end else begin
            case (dst_state)
                DST_IDLE: begin
                    dst_psel_r <= 1'b0;
                    dst_penable_r <= 1'b0;
                    if (req_valid_dst_sync2) begin
                        // Start setup phase
                        dst_psel_r <= 1'b1;
                        dst_penable_r <= 1'b0;
                        dst_pwrite_r <= req_write_src;
                        dst_paddr_r <= req_addr_src;
                        dst_pwdata_r <= req_wdata_src;
                        dst_pstrb_r <= req_strb_src;
                        dst_pprot_r <= req_pprot_src;
                        dst_state <= DST_SETUP;
                    end
                end
                DST_SETUP: begin
                    dst_psel_r <= 1'b1;
                    dst_penable_r <= 1'b1;
                    dst_state <= DST_ACCESS;
                end
                DST_ACCESS: begin
                    dst_psel_r <= 1'b1;
                    dst_penable_r <= 1'b1;
                    if (dst_pready_i) begin
                        // Capture read data and error
                        rdata_dst <= dst_prdata_i;
                        rslverr_dst <= dst_pslverr_i;
                        data_valid_dst <= 1'b1;
                        dst_psel_r <= 1'b0;
                        dst_penable_r <= 1'b0;
                        dst_state <= DST_IDLE;
                    end
                end
                default: begin
                    dst_state <= DST_IDLE;
                end
            endcase
        end
    end

    // Synchronize read data and error back to source
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            rdata_src <= {DATA_WIDTH{1'b0}};
            rslverr_src <= 1'b0;
        end else begin
            if (data_valid_dst_sync2) begin
                rdata_src <= rdata_dst;
                rslverr_src <= rslverr_dst;
            end
        end
    end

    // Assign outputs
    assign src_pready_o = src_pready_r;
    assign src_prdata_o = src_prdata_r;
    assign src_pslverr_o = src_pslverr_r;

    assign dst_psel_o = dst_psel_r;
    assign dst_penable_o = dst_penable_r;
    assign dst_pwrite_o = dst_pwrite_r;
    assign dst_paddr_o = dst_paddr_r;
    assign dst_pwdata_o = dst_pwdata_r;
    assign dst_pstrb_o = dst_pstrb_r;
    assign dst_pprot_o = dst_pprot_r;

endmodule
