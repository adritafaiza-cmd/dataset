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
    localparam AW = LOG_DEPTH;

    // Source domain state
    reg  [ADDR_WIDTH-1:0] src_addr_r;
    reg  [DATA_WIDTH-1:0] src_wdata_r;
    reg  [DATA_WIDTH/8-1:0] src_strb_r;
    reg  [2:0] src_pprot_r;
    reg  src_write_r;
    reg  src_valid_r;
    reg  src_busy_r;

    // Destination domain state
    reg  [ADDR_WIDTH-1:0] dst_addr_r;
    reg  [DATA_WIDTH-1:0] dst_wdata_r;
    reg  [DATA_WIDTH/8-1:0] dst_strb_r;
    reg  [2:0] dst_pprot_r;
    reg  dst_write_r;
    reg  dst_valid_r;
    reg  dst_busy_r;
    reg  dst_phase_r; // 0: setup, 1: access

    // Response path: dst -> src
    reg  [DATA_WIDTH-1:0] resp_data_r;
    reg  resp_err_r;
    reg  resp_valid_r;

    // Synchronization signals
    // src_valid -> dst
    reg  [2:0] src_valid_sync_r;
    // dst_done -> src
    reg  [2:0] dst_done_sync_r;
    // src_done -> dst (to clear dst_valid)
    reg  [2:0] src_done_sync_r;

    // FIFO pointers
    reg  [AW-1:0] src_wr_ptr_r;
    reg  [AW-1:0] dst_rd_ptr_r;

    // Synchronizers
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni)
            src_valid_sync_r <= 3'b000;
        else
            src_valid_sync_r <= {src_valid_sync_r[1:0], src_valid_r};
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni)
            dst_done_sync_r <= 3'b000;
        else
            dst_done_sync_r <= {dst_done_sync_r[1:0], dst_busy_r};
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni)
            src_done_sync_r <= 3'b000;
        else
            src_done_sync_r <= {src_done_sync_r[1:0], src_busy_r};
    end

    // Source domain logic
    wire src_idle = !src_busy_r && !src_valid_r;
    wire src_setup = src_psel_i && !src_penable_i;
    wire src_access = src_psel_i && src_penable_i;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_addr_r   <= {ADDR_WIDTH{1'b0}};
            src_wdata_r  <= {DATA_WIDTH{1'b0}};
            src_strb_r   <= {(DATA_WIDTH/8){1'b0}};
            src_pprot_r  <= 3'b000;
            src_write_r  <= 1'b0;
            src_valid_r  <= 1'b0;
            src_busy_r   <= 1'b0;
            src_wr_ptr_r <= {AW{1'b0}};
            resp_data_r  <= {DATA_WIDTH{1'b0}};
            resp_err_r   <= 1'b0;
            resp_valid_r <= 1'b0;
        end else begin
            // Capture request during setup phase
            if (src_setup && src_idle) begin
                src_addr_r   <= src_paddr_i;
                src_wdata_r  <= src_pwdata_i;
                src_strb_r   <= src_pstrb_i;
                src_pprot_r  <= src_pprot_i;
                src_write_r  <= src_pwrite_i;
                src_valid_r  <= 1'b1;
                src_busy_r   <= 1'b1;
                src_wr_ptr_r <= src_wr_ptr_r + 1'b1;
            end

            // Handle response from destination
            if (resp_valid_r) begin
                resp_valid_r <= 1'b0;
                src_busy_r   <= 1'b0;
            end

            // Clear valid when destination has consumed it
            if (src_valid_r && dst_done_sync_r[2]) begin
                src_valid_r <= 1'b0;
            end
        end
    end

    // Source outputs
    assign src_pready_o  = src_idle;
    assign src_prdata_o  = resp_data_r;
    assign src_pslverr_o = resp_err_r;

    // Destination domain logic
    wire dst_idle = !dst_busy_r && !dst_valid_r;
    wire dst_setup_active = dst_valid_r && !dst_phase_r;
    wire dst_access_active = dst_valid_r && dst_phase_r;

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_addr_r   <= {ADDR_WIDTH{1'b0}};
            dst_wdata_r  <= {DATA_WIDTH{1'b0}};
            dst_strb_r   <= {(DATA_WIDTH/8){1'b0}};
            dst_pprot_r  <= 3'b000;
            dst_write_r  <= 1'b0;
            dst_valid_r  <= 1'b0;
            dst_busy_r   <= 1'b0;
            dst_phase_r  <= 1'b0;
            dst_rd_ptr_r <= {AW{1'b0}};
        end else begin
            // Load new request from source when valid is synchronized
            if (src_valid_sync_r[2] && dst_idle) begin
                dst_addr_r   <= src_addr_r;
                dst_wdata_r  <= src_wdata_r;
                dst_strb_r   <= src_strb_r;
                dst_pprot_r  <= src_pprot_r;
                dst_write_r  <= src_write_r;
                dst_valid_r  <= 1'b1;
                dst_busy_r   <= 1'b1;
                dst_phase_r  <= 1'b0;
                dst_rd_ptr_r <= dst_rd_ptr_r + 1'b1;
            end

            // Advance phase: setup -> access
            if (dst_setup_active && dst_pready_i) begin
                dst_phase_r <= 1'b1;
            end

            // Complete transfer: access phase with pready
            if (dst_access_active && dst_pready_i) begin
                dst_valid_r <= 1'b0;
                dst_busy_r  <= 1'b0;
                dst_phase_r <= 1'b0;
            end
        end
    end

    // Destination outputs
    assign dst_psel_o   = dst_valid_r;
    assign dst_penable_o = dst_phase_r;
    assign dst_pwrite_o = dst_write_r;
    assign dst_paddr_o  = dst_addr_r;
    assign dst_pwdata_o = dst_wdata_r;
    assign dst_pstrb_o  = dst_strb_r;
    assign dst_pprot_o  = dst_pprot_r;

    // Response path: capture dst response and send back to src
    // We need to synchronize the response data and error back to src domain
    // Use a simple handshake: when dst completes, latch the response and
    // send a pulse to src domain

    reg  [DATA_WIDTH-1:0] resp_data_dst_r;
    reg  resp_err_dst_r;
    reg  resp_pulse_dst_r;

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            resp_data_dst_r  <= {DATA_WIDTH{1'b0}};
            resp_err_dst_r   <= 1'b0;
            resp_pulse_dst_r <= 1'b0;
        end else begin
            resp_pulse_dst_r <= 1'b0;
            if (dst_access_active && dst_pready_i) begin
                resp_data_dst_r  <= dst_prdata_i;
                resp_err_dst_r   <= dst_pslverr_i;
                resp_pulse_dst_r <= 1'b1;
            end
        end
    end

    // Synchronize response pulse to src domain
    reg  [2:0] resp_pulse_sync_r;
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni)
            resp_pulse_sync_r <= 3'b000;
        else
            resp_pulse_sync_r <= {resp_pulse_sync_r[1:0], resp_pulse_dst_r};
    end

    // Synchronize response data and error to src domain
    // Since the data is stable when the pulse is asserted, we can use
    // a simple approach: latch the data in src domain when pulse arrives
    reg  [DATA_WIDTH-1:0] resp_data_src_r;
    reg  resp_err_src_r;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            resp_data_src_r <= {DATA_WIDTH{1'b0}};
            resp_err_src_r  <= 1'b0;
        end else if (resp_pulse_sync_r[2] && !resp_pulse_sync_r[1]) begin
            resp_data_src_r <= resp_data_dst_r;
            resp_err_src_r  <= resp_err_dst_r;
        end
    end

    // Update resp_valid_r in src domain
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni)
            resp_valid_r <= 1'b0;
        else
            resp_valid_r <= resp_pulse_sync_r[2] && !resp_pulse_sync_r[1];
    end

    // Override resp_data_r and resp_err_r with synchronized values
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            resp_data_r <= {DATA_WIDTH{1'b0}};
            resp_err_r  <= 1'b0;
        end else if (resp_pulse_sync_r[2] && !resp_pulse_sync_r[1]) begin
            resp_data_r <= resp_data_dst_r;
            resp_err_r  <= resp_err_dst_r;
        end
    end

endmodule
