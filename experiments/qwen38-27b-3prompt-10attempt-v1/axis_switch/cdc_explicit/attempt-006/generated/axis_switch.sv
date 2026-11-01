module axis_switch #
(
    parameter S_COUNT = 4,
    parameter M_COUNT = 4,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter ID_ENABLE = 0,
    parameter S_ID_WIDTH = 8,
    parameter M_ID_WIDTH = S_ID_WIDTH+$clog2(S_COUNT),
    parameter M_DEST_WIDTH = 1,
    parameter S_DEST_WIDTH = M_DEST_WIDTH+$clog2(M_COUNT),
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1,
    parameter M_BASE = 0,
    parameter M_TOP = 0,
    parameter M_CONNECT = {M_COUNT{{S_COUNT{1'b1}}}},
    parameter UPDATE_TID = 0,
    parameter S_REG_TYPE = 0,
    parameter M_REG_TYPE = 2,
    parameter ARB_TYPE_ROUND_ROBIN = 1,
    parameter ARB_LSB_HIGH_PRIORITY = 1
)
(
    input  wire                             clk,
    input  wire                             rst,
    /*
     * AXI Stream inputs
     */
    input  wire [S_COUNT*DATA_WIDTH-1:0]    s_axis_tdata,
    input  wire [S_COUNT*KEEP_WIDTH-1:0]    s_axis_tkeep,
    input  wire [S_COUNT-1:0]               s_axis_tvalid,
    output wire [S_COUNT-1:0]               s_axis_tready,
    input  wire [S_COUNT-1:0]               s_axis_tlast,
    input  wire [S_COUNT*S_ID_WIDTH-1:0]    s_axis_tid,
    input  wire [S_COUNT*S_DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [S_COUNT*USER_WIDTH-1:0]    s_axis_tuser,
    /*
     * AXI Stream outputs
     */
    output wire [M_COUNT*DATA_WIDTH-1:0]    m_axis_tdata,
    output wire [M_COUNT*KEEP_WIDTH-1:0]    m_axis_tkeep,
    output wire [M_COUNT-1:0]               m_axis_tvalid,
    input  wire [M_COUNT-1:0]               m_axis_tready,
    output wire [M_COUNT-1:0]               m_axis_tlast,
    output wire [M_COUNT*M_ID_WIDTH-1:0]    m_axis_tid,
    output wire [M_COUNT*M_DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [M_COUNT*USER_WIDTH-1:0]    m_axis_tuser
);

    // Internal signals
    wire [S_COUNT-1:0] s_tvalid_int;
    wire [S_COUNT-1:0] s_tready_int;
    wire [S_COUNT-1:0] s_tlast_int;
    wire [S_COUNT*S_ID_WIDTH-1:0] s_tid_int;
    wire [S_COUNT*S_DEST_WIDTH-1:0] s_tdest_int;
    wire [S_COUNT*USER_WIDTH-1:0] s_tuser_int;
    wire [S_COUNT*DATA_WIDTH-1:0] s_tdata_int;
    wire [S_COUNT*KEEP_WIDTH-1:0] s_tkeep_int;

    // Register input side if S_REG_TYPE != 0
    generate
        if (S_REG_TYPE != 0) begin : gen_s_reg
            reg [S_COUNT-1:0] s_tvalid_r;
            reg [S_COUNT-1:0] s_tlast_r;
            reg [S_COUNT*S_ID_WIDTH-1:0] s_tid_r;
            reg [S_COUNT*S_DEST_WIDTH-1:0] s_tdest_r;
            reg [S_COUNT*USER_WIDTH-1:0] s_tuser_r;
            reg [S_COUNT*DATA_WIDTH-1:0] s_tdata_r;
            reg [S_COUNT*KEEP_WIDTH-1:0] s_tkeep_r;

            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    s_tvalid_r <= {S_COUNT{1'b0}};
                    s_tlast_r <= {S_COUNT{1'b0}};
                    s_tid_r <= {S_COUNT*S_ID_WIDTH{1'b0}};
                    s_tdest_r <= {S_COUNT*S_DEST_WIDTH{1'b0}};
                    s_tuser_r <= {S_COUNT*USER_WIDTH{1'b0}};
                    s_tdata_r <= {S_COUNT*DATA_WIDTH{1'b0}};
                    s_tkeep_r <= {S_COUNT*KEEP_WIDTH{1'b0}};
                end else begin
                    for (genvar i = 0; i < S_COUNT; i = i + 1) begin : gen_s_reg_i
                        if (s_axis_tvalid[i] && s_tready_int[i]) begin
                            s_tvalid_r[i] <= 1'b1;
                            s_tlast_r[i] <= s_axis_tlast[i];
                            s_tid_r[i*S_ID_WIDTH +: S_ID_WIDTH] <= s_axis_tid[i*S_ID_WIDTH +: S_ID_WIDTH];
                            s_tdest_r[i*S_DEST_WIDTH +: S_DEST_WIDTH] <= s_axis_tdest[i*S_DEST_WIDTH +: S_DEST_WIDTH];
                            s_tuser_r[i*USER_WIDTH +: USER_WIDTH] <= s_axis_tuser[i*USER_WIDTH +: USER_WIDTH];
                            s_tdata_r[i*DATA_WIDTH +: DATA_WIDTH] <= s_axis_tdata[i*DATA_WIDTH +: DATA_WIDTH];
                            s_tkeep_r[i*KEEP_WIDTH +: KEEP_WIDTH] <= s_axis_tkeep[i*KEEP_WIDTH +: KEEP_WIDTH];
                        end else begin
                            s_tvalid_r[i] <= 1'b0;
                        end
                    end
                end
            end

            assign s_tvalid_int = s_tvalid_r;
            assign s_tlast_int = s_tlast_r;
            assign s_tid_int = s_tid_r;
            assign s_tdest_int = s_tdest_r;
            assign s_tuser_int = s_tuser_r;
            assign s_tdata_int = s_tdata_r;
            assign s_tkeep_int = s_tkeep_r;
            assign s_axis_tready = s_tready_int;
        end else begin : gen_s_no_reg
            assign s_tvalid_int = s_axis_tvalid;
            assign s_tlast_int = s_axis_tlast;
            assign s_tid_int = s_axis_tid;
            assign s_tdest_int = s_axis_tdest;
            assign s_tuser_int = s_axis_tuser;
            assign s_tdata_int = s_axis_tdata;
            assign s_tkeep_int = s_axis_tkeep;
            assign s_axis_tready = s_tready_int;
        end
    endgenerate

    // Arbitration and routing
    // For each output m, determine which input s is granted
    wire [M_COUNT-1:0] m_tvalid_int;
    wire [M_COUNT-1:0] m_tready_int;
    wire [M_COUNT-1:0] m_tlast_int;
    wire [M_COUNT*M_ID_WIDTH-1:0] m_tid_int;
    wire [M_COUNT*M_DEST_WIDTH-1:0] m_tdest_int;
    wire [M_COUNT*USER_WIDTH-1:0] m_tuser_int;
    wire [M_COUNT*DATA_WIDTH-1:0] m_tdata_int;
    wire [M_COUNT*KEEP_WIDTH-1:0] m_tkeep_int;

    // Per-output arbitration
    // We need to track round-robin state per output
    reg [M_COUNT-1:0][$clog2(S_COUNT)-1:0] rr_ptr;

    // For each output m, compute the grant
    // request[m][s] = s_tvalid_int[s] && (s_tdest_int[s] == m) && M_CONNECT[m*S_COUNT+s]
    // Then arbitrate among requests

    // Let's define helper signals
    wire [M_COUNT-1:0][S_COUNT-1:0] req;
    wire [M_COUNT-1:0][S_COUNT-1:0] grant;
    wire [M_COUNT-1:0] any_req;

    genvar m, s;
    generate
        for (m = 0; m < M_COUNT; m = m + 1) begin : gen_out
            // Compute requests for this output
            for (s = 0; s < S_COUNT; s = s + 1) begin : gen_req
                assign req[m][s] = s_tvalid_int[s] && 
                                   (s_tdest_int[s*S_DEST_WIDTH +: S_DEST_WIDTH] == m[S_DEST_WIDTH-1:0]) &&
                                   M_CONNECT[m*S_COUNT + s];
            end

            assign any_req[m] = |req[m];

            // Arbitration
            if (ARB_TYPE_ROUND_ROBIN) begin : gen_rr
                // Round-robin arbitration
                // We need to find the first request at or after rr_ptr[m]
                // Create a rotated request vector
                wire [S_COUNT-1:0] req_rot;
                wire [S_COUNT-1:0] grant_rot;
                wire [$clog2(S_COUNT)-1:0] grant_idx_rot;

                // Rotate req so that rr_ptr[m] is at position 0
                // This is complex in Verilog, so let's use a different approach
                // We'll use a priority encoder with masking

                // Mask requests before rr_ptr[m]
                wire [S_COUNT-1:0] req_masked;
                wire [S_COUNT-1:0] req_masked_low;
                wire [S_COUNT-1:0] req_masked_high;

                // req_masked_low: requests with index < rr_ptr[m]
                // req_masked_high: requests with index >= rr_ptr[m]
                for (s = 0; s < S_COUNT; s = s + 1) begin : gen_mask
                    assign req_masked_low[s] = req[m][s] && (s < rr_ptr[m]);
                    assign req_masked_high[s] = req[m][s] && (s >= rr_ptr[m]);
                end

                wire [S_COUNT-1:0] req_priority;
                // If there's a request in high part, use that; otherwise use low part
                assign req_priority = (|req_masked_high) ? req_masked_high : req_masked_low;

                // Find the lowest set bit in req_priority
                // For LSB high priority, we want the lowest index
                // For MSB high priority, we want the highest index
                if (ARB_LSB_HIGH_PRIORITY) begin : gen_lsb
                    // Lowest set bit
                    wire [S_COUNT-1:0] grant_lsb;
                    for (s = 0; s < S_COUNT; s = s + 1) begin : gen_lsb_i
                        assign grant_lsb[s] = req_priority[s] && ~(req_priority[s-1:0] != 0);
                    end
                    // Handle s=0 specially
                    assign grant_lsb[0] = req_priority[0];
                    for (s = 1; s < S_COUNT; s = s + 1) begin : gen_lsb_i2
                        assign grant_lsb[s] = req_priority[s] && ~(req_priority[s-1:0] != 0);
                    end
                    assign grant[m] = grant_lsb;
                end else begin : gen_msb
                    // Highest set bit
                    wire [S_COUNT-1:0] grant_msb;
                    for (s = 0; s < S_COUNT; s = s + 1) begin : gen_msb_i
                        assign grant_msb[s] = req_priority[s] && ~(req_priority[S_COUNT-1:s+1] != 0);
                    end
                    assign grant[m] = grant_msb;
                end

                // Update round-robin pointer
                always @(posedge clk or posedge rst) begin
                    if (rst) begin
                        rr_ptr[m] <= 0;
                    end else if (any_req[m] && m_tready_int[m]) begin
                        // Find the granted index and set rr_ptr to next
                        // We need to find which s was granted
                        wire [S_COUNT-1:0] grant_onehot = grant[m];
                        // Find index of grant
                        wire [$clog2(S_COUNT)-1:0] grant_idx;
                        for (s = 0; s < S_COUNT; s = s + 1) begin : gen_idx
                            assign grant_idx = grant_onehot[s] ? s[$clog2(S_COUNT)-1:0] : grant_idx;
                        end
                        // This approach is problematic. Let's use a different method.
                        // We'll compute the next pointer based on the grant
                        // If grant is at index g, next pointer is (g+1) % S_COUNT
                        // But we need to handle the case where no grant (shouldn't happen if any_req)
                        // Let's just set rr_ptr to the granted index + 1
                        // We need to decode the one-hot to binary
                        wire [$clog2(S_COUNT)-1:0] g_idx;
                        for (s = 0; s < S_COUNT; s = s + 1) begin : gen_gidx
                            assign g_idx = grant_onehot[s] ? s[$clog2(S_COUNT)-1:0] : g_idx;
                        end
                        rr_ptr[m] <= (g_idx == S_COUNT-1) ? 0 : g_idx + 1;
                    end
                end
            end else begin : gen_fixed
                // Fixed priority arbitration
                if (ARB_LSB_HIGH_PRIORITY) begin : gen_fixed_lsb
                    // Lowest index has highest priority
                    wire [S_COUNT-1:0] grant_fixed;
                    for (s = 0; s < S_COUNT; s = s + 1) begin : gen_fixed_lsb_i
                        assign grant_fixed[s] = req[m][s] && ~(req[m][s-1:0] != 0);
                    end
                    assign grant_fixed[0] = req[m][0];
                    for (s = 1; s < S_COUNT; s = s + 1) begin : gen_fixed_lsb_i2
                        assign grant_fixed[s] = req[m][s] && ~(req[m][s-1:0] != 0);
                    end
                    assign grant[m] = grant_fixed;
                end else begin : gen_fixed_msb
                    // Highest index has highest priority
                    wire [S_COUNT-1:0] grant_fixed;
                    for (s = 0; s < S_COUNT; s = s + 1) begin : gen_fixed_msb_i
                        assign grant_fixed[s] = req[m][s] && ~(req[m][S_COUNT-1:s+1] != 0);
                    end
                    assign grant[m] = grant_fixed;
                end
            end
        end
    endgenerate

    // Output muxing
    generate
        for (m = 0; m < M_COUNT; m = m + 1) begin : gen_out_mux
            // Mux data from granted input
            wire [DATA_WIDTH-1:0] m_data_mux;
            wire [KEEP_WIDTH-1:0] m_keep_mux;
            wire m_last_mux;
            wire [S_ID_WIDTH-1:0] m_tid_mux;
            wire [USER_WIDTH-1:0] m_user_mux;

            for (s = 0; s < S_COUNT; s = s + 1) begin : gen_mux
                assign m_data_mux = grant[m][s] ? s_tdata_int[s*DATA_WIDTH +: DATA_WIDTH] : m_data_mux;
                assign m_keep_mux = grant[m][s] ? s_tkeep_int[s*KEEP_WIDTH +: KEEP_WIDTH] : m_keep_mux;
                assign m_last_mux = grant[m][s] ? s_tlast_int[s] : m_last_mux;
                assign m_tid_mux = grant[m][s] ? s_tid_int[s*S_ID_WIDTH +: S_ID_WIDTH] : m_tid_mux;
                assign m_user_mux = grant[m][s] ? s_tuser_int[s*USER_WIDTH +: USER_WIDTH] : m_user_mux;
            end

            assign m_tvalid_int[m] = any_req[m];
            assign m_tlast_int[m] = m_last_mux;
            assign m_tdata_int[m*DATA_WIDTH +: DATA_WIDTH] = m_data_mux;
            assign m_tkeep_int[m*KEEP_WIDTH +: KEEP_WIDTH] = m_keep_mux;
            assign m_tuser_int[m*USER_WIDTH +: USER_WIDTH] = m_user_mux;

            // TID handling
            if (UPDATE_TID) begin : gen_update_tid
                // Update TID by adding source index
                wire [M_ID_WIDTH-1:0] m_tid_new;
                assign m_tid_new[M_ID_WIDTH-1:S_ID_WIDTH] = m[$clog2(S_COUNT)-1:0]; // source index
                assign m_tid_new[S_ID_WIDTH-1:0] = m_tid_mux;
                assign m_tid_int[m*M_ID_WIDTH +: M_ID_WIDTH] = m_tid_new;
            end else begin : gen_no_update_tid
                // Pass through TID, zero-extend if needed
                assign m_tid_int[m*M_ID_WIDTH +: M_ID_WIDTH] = {M_ID_WIDTH-S_ID_WIDTH{1'b0}, m_tid_mux};
            end

            // TDEST handling
            if (M_DEST_WIDTH > 0) begin : gen_dest
                assign m_tdest_int[m*M_DEST_WIDTH +: M_DEST_WIDTH] = m[M_DEST_WIDTH-1:0];
            end else begin : gen_no_dest
                assign m_tdest_int = {M_COUNT*M_DEST_WIDTH{1'b0}};
            end
        end
    endgenerate

    // Input ready generation
    // s_tready_int[s] = 1 if the destination output is ready
    generate
        for (s = 0; s < S_COUNT; s = s + 1) begin : gen_s_ready
            wire [M_COUNT-1:0] dest_ready;
            for (m = 0; m < M_COUNT; m = m + 1) begin : gen_dest_ready
                assign dest_ready[m] = m_tready_int[m] && M_CONNECT[m*S_COUNT + s];
            end
            // s is ready if its destination is ready
            // We need to check if the specific destination is ready
            // s_tdest_int[s] gives the destination
            wire [S_DEST_WIDTH-1:0] s_dest = s_tdest_int[s*S_DEST_WIDTH +: S_DEST_WIDTH];
            assign s_tready_int[s] = dest_ready[s_dest];
        end
    endgenerate

    // Register output side if M_REG_TYPE != 0
    generate
        if (M_REG_TYPE != 0) begin : gen_m_reg
            reg [M_COUNT-1:0] m_tvalid_r;
            reg [M_COUNT-1:0] m_tlast_r;
            reg [M_COUNT*M_ID_WIDTH-1:0] m_tid_r;
            reg [M_COUNT*M_DEST_WIDTH-1:0] m_tdest_r;
            reg [M_COUNT*USER_WIDTH-1:0] m_tuser_r;
            reg [M_COUNT*DATA_WIDTH-1:0] m_tdata_r;
            reg [M_COUNT*KEEP_WIDTH-1:0] m_tkeep_r;

            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    m_tvalid_r <= {M_COUNT{1'b0}};
                    m_tlast_r <= {M_COUNT{1'b0}};
                    m_tid_r <= {M_COUNT*M_ID_WIDTH{1'b0}};
                    m_tdest_r <= {M_COUNT*M_DEST_WIDTH{1'b0}};
                    m_tuser_r <= {M_COUNT*USER_WIDTH{1'b0}};
                    m_tdata_r <= {M_COUNT*DATA_WIDTH{1'b0}};
                    m_tkeep_r <= {M_COUNT*KEEP_WIDTH{1'b0}};
                end else begin
                    for (genvar i = 0; i < M_COUNT; i = i + 1) begin : gen_m_reg_i
                        if (m_tvalid_int[i] && m_tready_int[i]) begin
                            m_tvalid_r[i] <= 1'b1;
                            m_tlast_r[i] <= m_tlast_int[i];
                            m_tid_r[i*M_ID_WIDTH +: M_ID_WIDTH] <= m_tid_int[i*M_ID_WIDTH +: M_ID_WIDTH];
                            m_tdest_r[i*M_DEST_WIDTH +: M_DEST_WIDTH] <= m_tdest_int[i*M_DEST_WIDTH +: M_DEST_WIDTH];
                            m_tuser_r[i*USER_WIDTH +: USER_WIDTH] <= m_tuser_int[i*USER_WIDTH +: USER_WIDTH];
                            m_tdata_r[i*DATA_WIDTH +: DATA_WIDTH] <= m_tdata_int[i*DATA_WIDTH +: DATA_WIDTH];
                            m_tkeep_r[i*KEEP_WIDTH +: KEEP_WIDTH] <= m_tkeep_int[i*KEEP_WIDTH +: KEEP_WIDTH];
                        end else begin
                            m_tvalid_r[i] <= 1'b0;
                        end
                    end
                end
            end

            assign m_axis_tvalid = m_tvalid_r;
            assign m_axis_tlast = m_tlast_r;
            assign m_axis_tid = m_tid_r;
            assign m_axis_tdest = m_tdest_r;
            assign m_axis_tuser = m_tuser_r;
            assign m_axis_tdata = m_tdata_r;
            assign m_axis_tkeep = m_tkeep_r;
            assign m_tready_int = m_axis_tready;
        end else begin : gen_m_no_reg
            assign m_axis_tvalid = m_tvalid_int;
            assign m_axis_tlast = m_tlast_int;
            assign m_axis_tid = m_tid_int;
            assign m_axis_tdest = m_tdest_int;
            assign m_axis_tuser = m_tuser_int;
            assign m_axis_tdata = m_tdata_int;
            assign m_axis_tkeep = m_tkeep_int;
            assign m_tready_int = m_axis_tready;
        end
    endgenerate

endmodule
