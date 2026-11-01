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
    wire        src_req_valid;
    wire        src_req_ready;
    wire        dst_req_valid;
    wire        dst_req_ready;
    wire        dst_done_valid;
    wire        dst_done_ready;
    wire        src_done_valid;
    wire        src_done_ready;

    // Source side: capture request when APB setup phase completes
    // APB transfer: setup phase (psel=1, penable=0), access phase (psel=1, penable=1)
    // We capture the request at the start of the access phase (when penable goes high)
    // and hold it until the destination completes.

    reg         src_busy;
    reg         src_pwrite_r;
    reg  [ADDR_WIDTH-1:0] src_paddr_r;
    reg  [DATA_WIDTH-1:0] src_pwdata_r;
    reg  [DATA_WIDTH/8-1:0] src_pstrb_r;
    reg  [2:0] src_pprot_r;

    // Destination side: hold request fields stable during transfer
    reg         dst_busy;
    reg         dst_pwrite_r;
    reg  [ADDR_WIDTH-1:0] dst_paddr_r;
    reg  [DATA_WIDTH-1:0] dst_pwdata_r;
    reg  [DATA_WIDTH/8-1:0] dst_pstrb_r;
    reg  [2:0] dst_pprot_r;
    reg         dst_penable_r;

    // Response data from destination
    reg  [DATA_WIDTH-1:0] dst_prdata_r;
    reg         dst_pslverr_r;

    // Source side response
    reg  [DATA_WIDTH-1:0] src_prdata_r;
    reg         src_pslverr_r;

    // CDC: request valid signal (src -> dst)
    // Use a 2-phase handshake with level signals synchronized
    // Since we have one outstanding transaction, we can use a simple valid/ready handshake
    // with proper CDC synchronization.

    // For the request path (src -> dst):
    // src asserts req_valid, dst synchronizes and asserts req_ready
    // For the response path (dst -> src):
    // dst asserts done_valid, src synchronizes and asserts done_ready

    // Request valid: src -> dst
    wire        req_valid_src;
    wire        req_valid_dst;
    wire        req_ready_src;
    wire        req_ready_dst;

    // Response valid: dst -> src
    wire        done_valid_dst;
    wire        done_valid_src;
    wire        done_ready_dst;
    wire        done_ready_src;

    // Assign internal signals
    assign src_req_valid = req_valid_src;
    assign src_req_ready = req_ready_src;
    assign dst_req_valid = req_valid_dst;
    assign dst_req_ready = req_ready_dst;
    assign dst_done_valid = done_valid_dst;
    assign dst_done_ready = done_ready_dst;
    assign src_done_valid = done_valid_src;
    assign src_done_ready = done_ready_src;

    // Source side state machine
    // States: IDLE, WAIT_DST
    localparam SRC_IDLE = 1'b0;
    localparam SRC_WAIT = 1'b1;

    reg src_state;

    // Destination side state machine
    // States: IDLE, SETUP, ACCESS
    localparam DST_IDLE = 2'b00;
    localparam DST_SETUP = 2'b01;
    localparam DST_ACCESS = 2'b10;

    reg [1:0] dst_state;

    // Source side logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_state <= SRC_IDLE;
            src_busy <= 1'b0;
            src_pwrite_r <= 1'b0;
            src_paddr_r <= {ADDR_WIDTH{1'b0}};
            src_pwdata_r <= {DATA_WIDTH{1'b0}};
            src_pstrb_r <= {(DATA_WIDTH/8){1'b0}};
            src_pprot_r <= 3'b000;
            src_prdata_r <= {DATA_WIDTH{1'b0}};
            src_pslverr_r <= 1'b0;
        end else begin
            case (src_state)
                SRC_IDLE: begin
                    if (src_psel_i && !src_penable_i && src_req_ready) begin
                        // Start of setup phase, request is ready to be accepted
                        // Capture the request
                        src_pwrite_r <= src_pwrite_i;
                        src_paddr_r <= src_paddr_i;
                        src_pwdata_r <= src_pwdata_i;
                        src_pstrb_r <= src_pstrb_i;
                        src_pprot_r <= src_pprot_i;
                        src_state <= SRC_WAIT;
                        src_busy <= 1'b1;
                    end
                end
                SRC_WAIT: begin
                    if (src_done_valid) begin
                        // Destination completed, return data
                        src_prdata_r <= src_prdata_r; // Will be updated from dst
                        src_pslverr_r <= src_pslverr_r; // Will be updated from dst
                        src_state <= SRC_IDLE;
                        src_busy <= 1'b0;
                    end
                end
                default: begin
                    src_state <= SRC_IDLE;
                    src_busy <= 1'b0;
                end
            endcase
        end
    end

    // Source outputs
    assign src_pready_o = (src_state == SRC_IDLE) ? 1'b1 : 1'b0;
    assign src_prdata_o = src_prdata_r;
    assign src_pslverr_o = src_pslverr_r;

    // Destination side logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_state <= DST_IDLE;
            dst_busy <= 1'b0;
            dst_pwrite_r <= 1'b0;
            dst_paddr_r <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_r <= {DATA_WIDTH{1'b0}};
            dst_pstrb_r <= {(DATA_WIDTH/8){1'b0}};
            dst_pprot_r <= 3'b000;
            dst_penable_r <= 1'b0;
            dst_prdata_r <= {DATA_WIDTH{1'b0}};
            dst_pslverr_r <= 1'b0;
        end else begin
            case (dst_state)
                DST_IDLE: begin
                    if (dst_req_valid) begin
                        // Accept request from source
                        dst_pwrite_r <= dst_pwrite_r; // Will be updated
                        dst_paddr_r <= dst_paddr_r; // Will be updated
                        dst_pwdata_r <= dst_pwdata_r; // Will be updated
                        dst_pstrb_r <= dst_pstrb_r; // Will be updated
                        dst_pprot_r <= dst_pprot_r; // Will be updated
                        dst_state <= DST_SETUP;
                        dst_busy <= 1'b1;
                        dst_penable_r <= 1'b0;
                    end
                end
                DST_SETUP: begin
                    // Setup phase: psel=1, penable=0
                    dst_penable_r <= 1'b0;
                    // Move to access phase
                    dst_state <= DST_ACCESS;
                end
                DST_ACCESS: begin
                    // Access phase: psel=1, penable=1
                    dst_penable_r <= 1'b1;
                    if (dst_pready_i) begin
                        // Transfer complete
                        dst_prdata_r <= dst_prdata_i;
                        dst_pslverr_r <= dst_pslverr_i;
                        dst_state <= DST_IDLE;
                        dst_busy <= 1'b0;
                        dst_penable_r <= 1'b0;
                    end
                end
                default: begin
                    dst_state <= DST_IDLE;
                    dst_busy <= 1'b0;
                    dst_penable_r <= 1'b0;
                end
            endcase
        end
    end

    // Destination outputs
    assign dst_psel_o = (dst_state == DST_SETUP) || (dst_state == DST_ACCESS);
    assign dst_penable_o = dst_penable_r;
    assign dst_pwrite_o = dst_pwrite_r;
    assign dst_paddr_o = dst_paddr_r;
    assign dst_pwdata_o = dst_pwdata_r;
    assign dst_pstrb_o = dst_pstrb_r;
    assign dst_pprot_o = dst_pprot_r;

    // CDC: Request valid (src -> dst)
    // Use a 2-flop synchronizer for the valid signal
    // The data is held stable on the source side until the destination acknowledges

    // Source side: assert req_valid when we have a request to send
    // We need to hold the request data stable until dst acknowledges

    // Let's use a different approach: 
    // Source holds the request in registers and asserts a valid signal
    // Destination synchronizes the valid signal and reads the data when valid is high
    // Since the data is held stable, we can use a simple synchronizer for valid
    // and the data will be stable when valid is sampled

    // Request valid: src -> dst
    reg [1:0] req_valid_sync;
    wire req_valid_dst_sync = req_valid_sync[1];

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            req_valid_sync <= 2'b00;
        end else begin
            req_valid_sync <= {req_valid_sync[0], src_req_valid};
        end
    end

    // Wait, this is wrong. The synchronizer should be in the destination clock domain.
    // Let me redo this.

    // Request valid: src -> dst
    // src asserts req_valid_src, dst synchronizes it
    reg [1:0] req_valid_sync_dst;
    wire req_valid_dst_sync = req_valid_sync_dst[1];

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            req_valid_sync_dst <= 2'b00;
        end else begin
            req_valid_sync_dst <= {req_valid_sync_dst[0], req_valid_src};
        end
    end

    // Request ready: dst -> src
    // dst asserts req_ready_dst, src synchronizes it
    reg [1:0] req_ready_sync_src;
    wire req_ready_src_sync = req_ready_sync_src[1];

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            req_ready_sync_src <= 2'b00;
        end else begin
            req_ready_sync_src <= {req_ready_sync_src[0], req_ready_dst};
        end
    end

    // Response valid: dst -> src
    // dst asserts done_valid_dst, src synchronizes it
    reg [1:0] done_valid_sync_src;
    wire done_valid_src_sync = done_valid_sync_src[1];

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            done_valid_sync_src <= 2'b00;
        end else begin
            done_valid_sync_src <= {done_valid_sync_src[0], done_valid_dst};
        end
    end

    // Response ready: src -> dst
    // src asserts done_ready_src, dst synchronizes it
    reg [1:0] done_ready_sync_dst;
    wire done_ready_dst_sync = done_ready_sync_dst[1];

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            done_ready_sync_dst <= 2'b00;
        end else begin
            done_ready_sync_dst <= {done_ready_sync_dst[0], done_ready_src};
        end
    end

    // Now let's properly implement the handshake

    // Source side: 
    // - When in IDLE and APB setup phase is active (psel=1, penable=0), 
    //   we can accept a new request if the destination is ready
    // - We capture the request and assert req_valid_src
    // - We wait for req_ready_src (synchronized from dst) to complete the handshake
    // - Then we wait for done_valid_src (synchronized from dst) to get the response

    // Destination side:
    // - When in IDLE and req_valid_dst_sync is high, we accept the request
    //   and assert req_ready_dst
    // - We perform the APB transfer (setup then access)
    // - When the transfer completes, we assert done_valid_dst
    // - We wait for done_ready_dst (synchronized from src) to complete the handshake

    // Let's redefine the signals properly

    // Source side request valid
    reg src_req_valid_r;

    // Source side request ready (synchronized from dst)
    wire src_req_ready_r = req_ready_src_sync;

    // Destination side request valid (synchronized from src)
    wire dst_req_valid_r = req_valid_dst_sync;

    // Destination side request ready
    reg dst_req_ready_r;

    // Destination side done valid
    reg dst_done_valid_r;

    // Destination side done ready (synchronized from src)
    wire dst_done_ready_r = done_ready_dst_sync;

    // Source side done valid (synchronized from dst)
    wire src_done_valid_r = done_valid_src_sync;

    // Source side done ready
    reg src_done_ready_r;

    // Assign the wire signals
    assign req_valid_src = src_req_valid_r;
    assign req_ready_dst = dst_req_ready_r;
    assign done_valid_dst = dst_done_valid_r;
    assign done_ready_src = src_done_ready_r;

    // Source side state machine (revised)
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_state <= SRC_IDLE;
            src_req_valid_r <= 1'b0;
            src_done_ready_r <= 1'b0;
            src_pwrite_r <= 1'b0;
            src_paddr_r <= {ADDR_WIDTH{1'b0}};
            src_pwdata_r <= {DATA_WIDTH{1'b0}};
            src_pstrb_r <= {(DATA_WIDTH/8){1'b0}};
            src_pprot_r <= 3'b000;
            src_prdata_r <= {DATA_WIDTH{1'b0}};
            src_pslverr_r <= 1'b0;
        end else begin
            case (src_state)
                SRC_IDLE: begin
                    src_req_valid_r <= 1'b0;
                    src_done_ready_r <= 1'b0;
                    if (src_psel_i && !src_penable_i && src_req_ready_r) begin
                        // Accept request
                        src_pwrite_r <= src_pwrite_i;
                        src_paddr_r <= src_paddr_i;
                        src_pwdata_r <= src_pwdata_i;
                        src_pstrb_r <= src_pstrb_i;
                        src_pprot_r <= src_pprot_i;
                        src_req_valid_r <= 1'b1;
                        src_state <= SRC_WAIT;
                    end
                end
                SRC_WAIT: begin
                    // Wait for destination to complete
                    if (src_done_valid_r) begin
                        // Get response data
                        src_prdata_r <= src_prdata_r; // Need to get from dst
                        src_pslverr_r <= src_pslverr_r; // Need to get from dst
                        src_done_ready_r <= 1'b1;
                        src_state <= SRC_IDLE;
                    end
                end
                default: begin
                    src_state <= SRC_IDLE;
                    src_req_valid_r <= 1'b0;
                    src_done_ready_r <= 1'b0;
                end
            endcase
        end
    end

    // Destination side state machine (revised)
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_state <= DST_IDLE;
            dst_req_ready_r <= 1'b0;
            dst_done_valid_r <= 1'b0;
            dst_pwrite_r <= 1'b0;
            dst_paddr_r <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_r <= {DATA_WIDTH{1'b0}};
            dst_pstrb_r <= {(DATA_WIDTH/8){1'b0}};
            dst_pprot_r <= 3'b000;
            dst_penable_r <= 1'b0;
            dst_prdata_r <= {DATA_WIDTH{1'b0}};
            dst_pslverr_r <= 1'b0;
        end else begin
            case (dst_state)
                DST_IDLE: begin
                    dst_req_ready_r <= 1'b0;
                    dst_done_valid_r <= 1'b0;
                    if (dst_req_valid_r) begin
                        // Accept request
                        dst_pwrite_r <= dst_pwrite_r; // Need to get from src
                        dst_paddr_r <= dst_paddr_r; // Need to get from src
                        dst_pwdata_r <= dst_pwdata_r; // Need to get from src
                        dst_pstrb_r <= dst_pstrb_r; // Need to get from src
                        dst_pprot_r <= dst_pprot_r; // Need to get from src
                        dst_req_ready_r <= 1'b1;
                        dst_state <= DST_SETUP;
                    end
                end
                DST_SETUP: begin
                    dst_penable_r <= 1'b0;
                    dst_state <= DST_ACCESS;
                end
                DST_ACCESS: begin
                    dst_penable_r <= 1'b1;
                    if (dst_pready_i) begin
                        // Transfer complete
                        dst_prdata_r <= dst_prdata_i;
                        dst_pslverr_r <= dst_pslverr_i;
                        dst_done_valid_r <= 1'b1;
                        dst_state <= DST_IDLE;
                    end
                end
                default: begin
                    dst_state <= DST_IDLE;
                    dst_req_ready_r <= 1'b0;
                    dst_done_valid_r <= 1'b0;
                    dst_penable_r <= 1'b0;
                end
            endcase
        end
    end

    // We need to transfer the request data from src to dst
    // Since the data is held stable on the src side until dst acknowledges,
    // we can use the dst clock to sample the data when dst_req_valid_r is high

    // But wait, the data is on the src side. We need to transfer it across the CDC.
    // The standard approach is to use a FIFO or to hold the data stable and use
    // a synchronizer for the valid signal, then sample the data in the dst domain.

    // Since the data is held stable on the src side, we can sample it in the dst domain
    // when the synchronized valid signal is high.

    // Let's add registers in the dst domain to capture the request data
    reg [ADDR_WIDTH-1:0] dst_paddr_captured;
    reg [DATA_WIDTH-1:0] dst_pwdata_captured;
    reg [DATA_WIDTH/8-1:0] dst_pstrb_captured;
    reg [2:0] dst_pprot_captured;
    reg dst_pwrite_captured;

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_paddr_captured <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_captured <= {DATA_WIDTH{1'b0}};
            dst_pstrb_captured <= {(DATA_WIDTH/8){1'b0}};
            dst_pprot_captured <= 3'b000;
            dst_pwrite_captured <= 1'b0;
        end else begin
            if (dst_req_valid_r) begin
                dst_paddr_captured <= src_paddr_r;
                dst_pwdata_captured <= src_pwdata_r;
                dst_pstrb_captured <= src_pstrb_r;
                dst_pprot_captured <= src_pprot_r;
                dst_pwrite_captured <= src_pwrite_r;
            end
        end
    end

    // Update the dst registers with the captured data
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_pwrite_r <= 1'b0;
            dst_paddr_r <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_r <= {DATA_WIDTH{1'b0}};
            dst_pstrb_r <= {(DATA_WIDTH/8){1'b0}};
            dst_pprot_r <= 3'b000;
        end else begin
            if (dst_state == DST_IDLE && dst_req_valid_r) begin
                dst_pwrite_r <= dst_pwrite_captured;
                dst_paddr_r <= dst_paddr_captured;
                dst_pwdata_r <= dst_pwdata_captured;
                dst_pstrb_r <= dst_pstrb_captured;
                dst_pprot_r <= dst_pprot_captured;
            end
        end
    end

    // Similarly, we need to transfer the response data from dst to src
    // The response data is held stable on the dst side until src acknowledges

    // Let's add registers in the src domain to capture the response data
    reg [DATA_WIDTH-1:0] src_prdata_captured;
    reg src_pslverr_captured;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_prdata_captured <= {DATA_WIDTH{1'b0}};
            src_pslverr_captured <= 1'b0;
        end else begin
            if (src_done_valid_r) begin
                src_prdata_captured <= dst_prdata_r;
                src_pslverr_captured <= dst_pslverr_r;
            end
        end
    end

    // Update the src registers with the captured response data
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_prdata_r <= {DATA_WIDTH{1'b0}};
            src_pslverr_r <= 1'b0;
        end else begin
            if (src_state == SRC_WAIT && src_done_valid_r) begin
                src_prdata_r <= src_prdata_captured;
                src_pslverr_r <= src_pslverr_captured;
            end
        end
    end

endmodule
