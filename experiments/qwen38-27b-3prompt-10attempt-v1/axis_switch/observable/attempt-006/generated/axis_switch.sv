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
    wire [S_COUNT-1:0] s_tvalid;
    wire [S_COUNT-1:0] s_tready;
    wire [S_COUNT-1:0] s_tlast;
    wire [S_COUNT*DATA_WIDTH-1:0] s_tdata;
    wire [S_COUNT*KEEP_WIDTH-1:0] s_tkeep;
    wire [S_COUNT*S_ID_WIDTH-1:0] s_tid;
    wire [S_COUNT*S_DEST_WIDTH-1:0] s_tdest;
    wire [S_COUNT*USER_WIDTH-1:0] s_tuser;

    // Source register stage
    generate
        if (S_REG_TYPE != 0) begin : gen_s_reg
            reg [S_COUNT-1:0] s_tvalid_r;
            reg [S_COUNT-1:0] s_tlast_r;
            reg [S_COUNT*DATA_WIDTH-1:0] s_tdata_r;
            reg [S_COUNT*KEEP_WIDTH-1:0] s_tkeep_r;
            reg [S_COUNT*S_ID_WIDTH-1:0] s_tid_r;
            reg [S_COUNT*S_DEST_WIDTH-1:0] s_tdest_r;
            reg [S_COUNT*USER_WIDTH-1:0] s_tuser_r;

            assign s_tvalid = s_tvalid_r;
            assign s_tlast = s_tlast_r;
            assign s_tdata = s_tdata_r;
            assign s_tkeep = s_tkeep_r;
            assign s_tid = s_tid_r;
            assign s_tdest = s_tdest_r;
            assign s_tuser = s_tuser_r;

            // Backpressure: can accept new data if register is empty or being read
            wire [S_COUNT-1:0] s_can_accept;
            genvar i;
            for (i = 0; i < S_COUNT; i = i + 1) begin : gen_s_can_accept
                assign s_can_accept[i] = ~s_tvalid_r[i] | s_tready[i];
            end

            always @(posedge clk) begin
                if (rst) begin
                    s_tvalid_r <= {S_COUNT{1'b0}};
                end else begin
                    for (i = 0; i < S_COUNT; i = i + 1) begin
                        if (s_axis_tvalid[i] && s_can_accept[i]) begin
                            s_tvalid_r[i] <= 1'b1;
                            s_tlast_r[i] <= s_axis_tlast[i];
                            s_tdata_r[i*DATA_WIDTH +: DATA_WIDTH] <= s_axis_tdata[i*DATA_WIDTH +: DATA_WIDTH];
                            s_tkeep_r[i*KEEP_WIDTH +: KEEP_WIDTH] <= s_axis_tkeep[i*KEEP_WIDTH +: KEEP_WIDTH];
                            s_tid_r[i*S_ID_WIDTH +: S_ID_WIDTH] <= s_axis_tid[i*S_ID_WIDTH +: S_ID_WIDTH];
                            s_tdest_r[i*S_DEST_WIDTH +: S_DEST_WIDTH] <= s_axis_tdest[i*S_DEST_WIDTH +: S_DEST_WIDTH];
                            s_tuser_r[i*USER_WIDTH +: USER_WIDTH] <= s_axis_tuser[i*USER_WIDTH +: USER_WIDTH];
                        end else if (s_tvalid_r[i] && s_tready[i]) begin
                            s_tvalid_r[i] <= 1'b0;
                        end
                    end
                end
            end

            assign s_axis_tready = s_can_accept;
        end else begin : gen_s_no_reg
            assign s_tvalid = s_axis_tvalid;
            assign s_tlast = s_axis_tlast;
            assign s_tdata = s_axis_tdata;
            assign s_tkeep = s_axis_tkeep;
            assign s_tid = s_axis_tid;
            assign s_tdest = s_axis_tdest;
            assign s_tuser = s_axis_tuser;
            assign s_axis_tready = s_tready;
        end
    endgenerate

    // Per-output arbitration and routing
    // For each output m, determine which source is selected
    // We use a simple arbitration: for each output, among all sources that can send to it,
    // select based on arbitration policy.

    // First, determine for each source which outputs it can connect to
    // M_CONNECT[m][s] indicates if source s can connect to output m

    // For each output m, we need to arbitrate among sources that:
    // 1. Have valid data
    // 2. Can connect to output m (M_CONNECT[m][s] == 1)
    // 3. The destination field matches (if S_DEST_WIDTH > 0)

    // Let's define the eligible sources for each output
    wire [M_COUNT-1:0][S_COUNT-1:0] eligible;
    genvar m;
    genvar s;
    for (m = 0; m < M_COUNT; m = m + 1) begin : gen_eligible
        for (s = 0; s < S_COUNT; s = s + 1) begin : gen_eligible_s
            wire dest_match;
            if (S_DEST_WIDTH > 0) begin
                assign dest_match = (s_tdest[s*S_DEST_WIDTH +: S_DEST_WIDTH] == m);
            end else begin
                assign dest_match = 1'b1;
            end
            assign eligible[m][s] = s_tvalid[s] && M_CONNECT[m][s] && dest_match;
        end
    end

    // Arbitration for each output
    // We'll implement round-robin or fixed priority based on ARB_TYPE_ROUND_ROBIN
    // For simplicity, let's implement fixed priority (LSB high priority) as default,
    // and round-robin if ARB_TYPE_ROUND_ROBIN is set.

    // For round-robin, we need to track the last granted source for each output
    reg [M_COUNT-1:0][$clog2(S_COUNT)-1:0] last_granted;

    // For each output, select the winning source
    wire [M_COUNT-1:0][S_COUNT-1:0] grant;
    wire [M_COUNT-1:0][$clog2(S_COUNT)-1:0] grant_idx;

    generate
        for (m = 0; m < M_COUNT; m = m + 1) begin : gen_arb
            // Fixed priority: lowest index wins
            wire [S_COUNT-1:0] fixed_priority_grant;
            wire [$clog2(S_COUNT)-1:0] fixed_priority_idx;
            
            // Round-robin: rotate eligible based on last_granted
            wire [S_COUNT-1:0] rr_eligible;
            wire [S_COUNT-1:0] rr_grant;
            wire [$clog2(S_COUNT)-1:0] rr_idx;

            if (ARB_TYPE_ROUND_ROBIN) begin : gen_rr
                // Rotate eligible vector so that last_granted+1 is at position 0
                // This is a simplified round-robin
                assign rr_eligible = eligible[m];
                
                // Find first set bit in rotated vector
                // For simplicity, we'll use a priority encoder on the rotated vector
                wire [S_COUNT-1:0] rotated;
                genvar r;
                for (r = 0; r < S_COUNT; r = r + 1) begin : gen_rotate
                    assign rotated[r] = eligible[m][(r + last_granted[m]) % S_COUNT];
                end
                
                // Priority encoder: find lowest set bit
                wire any_valid = |rotated;
                wire [$clog2(S_COUNT)-1:0] rot_idx;
                assign rot_idx = any_valid ? (rotated[0] ? 0 : 
                                              rotated[1] ? 1 : 
                                              (S_COUNT > 2) ? (rotated[2] ? 2 : 
                                                               (S_COUNT > 3) ? (rotated[3] ? 3 : 0) : 0) : 0) : 0;
                
                // Convert rotated index back to original index
                assign rr_idx = (rot_idx + last_granted[m]) % S_COUNT;
                
                // Create grant vector
                assign rr_grant = any_valid ? (1 << rr_idx) : {S_COUNT{1'b0}};
                
                assign grant[m] = rr_grant;
                assign grant_idx[m] = rr_idx;
            end else begin : gen_fixed
                // Fixed priority: lowest index wins
                wire any_valid = |eligible[m];
                wire [$clog2(S_COUNT)-1:0] fp_idx;
                assign fp_idx = any_valid ? (eligible[m][0] ? 0 : 
                                             eligible[m][1] ? 1 : 
                                             (S_COUNT > 2) ? (eligible[m][2] ? 2 : 
                                                              (S_COUNT > 3) ? (eligible[m][3] ? 3 : 0) : 0) : 0) : 0;
                
                assign fixed_priority_grant = any_valid ? (1 << fp_idx) : {S_COUNT{1'b0}};
                assign fixed_priority_idx = fp_idx;
                
                assign grant[m] = fixed_priority_grant;
                assign grant_idx[m] = fixed_priority_idx;
            end
        end
    endgenerate

    // Update last_granted for round-robin
    always @(posedge clk) begin
        if (rst) begin
            last_granted <= {M_COUNT{$clog2(S_COUNT){1'b0}}};
        end else begin
            for (m = 0; m < M_COUNT; m = m + 1) begin
                if (grant[m] != 0 && m_axis_tready[m]) begin
                    last_granted[m] <= grant_idx[m];
                end
            end
        end
    end

    // Determine which source each output is connected to
    // For each output m, the selected source is grant_idx[m] if grant[m] != 0

    // Mux the data from the selected source to each output
    wire [M_COUNT-1:0] m_tvalid;
    wire [M_COUNT-1:0] m_tlast;
    wire [M_COUNT*DATA_WIDTH-1:0] m_tdata;
    wire [M_COUNT*KEEP_WIDTH-1:0] m_tkeep;
    wire [M_COUNT*M_ID_WIDTH-1:0] m_tid;
    wire [M_COUNT*M_DEST_WIDTH-1:0] m_tdest;
    wire [M_COUNT*USER_WIDTH-1:0] m_tuser;

    generate
        for (m = 0; m < M_COUNT; m = m + 1) begin : gen_m_out
            wire has_grant = (grant[m] != 0);
            wire [$clog2(S_COUNT)-1:0] sel = grant_idx[m];
            
            assign m_tvalid[m] = has_grant;
            assign m_tlast[m] = has_grant ? s_tlast[sel] : 1'b0;
            assign m_tdata[m*DATA_WIDTH +: DATA_WIDTH] = has_grant ? s_tdata[sel*DATA_WIDTH +: DATA_WIDTH] : {DATA_WIDTH{1'b0}};
            assign m_tkeep[m*KEEP_WIDTH +: KEEP_WIDTH] = has_grant ? s_tkeep[sel*KEEP_WIDTH +: KEEP_WIDTH] : {KEEP_WIDTH{1'b0}};
            
            // ID handling
            if (ID_ENABLE) begin
                if (UPDATE_TID) begin
                    // Update TID: prepend source index
                    assign m_tid[m*M_ID_WIDTH +: M_ID_WIDTH] = has_grant ? {sel, s_tid[sel*S_ID_WIDTH +: S_ID_WIDTH]} : {M_ID_WIDTH{1'b0}};
                end else begin
                    assign m_tid[m*M_ID_WIDTH +: M_ID_WIDTH] = has_grant ? s_tid[sel*S_ID_WIDTH +: S_ID_WIDTH] : {M_ID_WIDTH{1'b0}};
                end
            end else begin
                assign m_tid[m*M_ID_WIDTH +: M_ID_WIDTH] = {M_ID_WIDTH{1'b0}};
            end
            
            // Destination
            if (M_DEST_WIDTH > 0) begin
                assign m_tdest[m*M_DEST_WIDTH +: M_DEST_WIDTH] = has_grant ? m[M_DEST_WIDTH-1:0] : {M_DEST_WIDTH{1'b0}};
            end else begin
                assign m_tdest[m*M_DEST_WIDTH +: M_DEST_WIDTH] = {M_DEST_WIDTH{1'b0}};
            end
            
            // User
            if (USER_ENABLE) begin
                assign m_tuser[m*USER_WIDTH +: USER_WIDTH] = has_grant ? s_tuser[sel*USER_WIDTH +: USER_WIDTH] : {USER_WIDTH{1'b0}};
            end else begin
                assign m_tuser[m*USER_WIDTH +: USER_WIDTH] = {USER_WIDTH{1'b0}};
            end
        end
    endgenerate

    // Output register stage
    generate
        if (M_REG_TYPE != 0) begin : gen_m_reg
            reg [M_COUNT-1:0] m_tvalid_r;
            reg [M_COUNT-1:0] m_tlast_r;
            reg [M_COUNT*DATA_WIDTH-1:0] m_tdata_r;
            reg [M_COUNT*KEEP_WIDTH-1:0] m_tkeep_r;
            reg [M_COUNT*M_ID_WIDTH-1:0] m_tid_r;
            reg [M_COUNT*M_DEST_WIDTH-1:0] m_tdest_r;
            reg [M_COUNT*USER_WIDTH-1:0] m_tuser_r;

            assign m_axis_tvalid = m_tvalid_r;
            assign m_axis_tlast = m_tlast_r;
            assign m_axis_tdata = m_tdata_r;
            assign m_axis_tkeep = m_tkeep_r;
            assign m_axis_tid = m_tid_r;
            assign m_axis_tdest = m_tdest_r;
            assign m_axis_tuser = m_tuser_r;

            // Backpressure: can accept new data if register is empty or being read
            wire [M_COUNT-1:0] m_can_accept;
            genvar j;
            for (j = 0; j < M_COUNT; j = j + 1) begin : gen_m_can_accept
                assign m_can_accept[j] = ~m_tvalid_r[j] | m_axis_tready[j];
            end

            always @(posedge clk) begin
                if (rst) begin
                    m_tvalid_r <= {M_COUNT{1'b0}};
                end else begin
                    for (j = 0; j < M_COUNT; j = j + 1) begin
                        if (m_tvalid[j] && m_can_accept[j]) begin
                            m_tvalid_r[j] <= 1'b1;
                            m_tlast_r[j] <= m_tlast[j];
                            m_tdata_r[j*DATA_WIDTH +: DATA_WIDTH] <= m_tdata[j*DATA_WIDTH +: DATA_WIDTH];
                            m_tkeep_r[j*KEEP_WIDTH +: KEEP_WIDTH] <= m_tkeep[j*KEEP_WIDTH +: KEEP_WIDTH];
                            m_tid_r[j*M_ID_WIDTH +: M_ID_WIDTH] <= m_tid[j*M_ID_WIDTH +: M_ID_WIDTH];
                            m_tdest_r[j*M_DEST_WIDTH +: M_DEST_WIDTH] <= m_tdest[j*M_DEST_WIDTH +: M_DEST_WIDTH];
                            m_tuser_r[j*USER_WIDTH +: USER_WIDTH] <= m_tuser[j*USER_WIDTH +: USER_WIDTH];
                        end else if (m_tvalid_r[j] && m_axis_tready[j]) begin
                            m_tvalid_r[j] <= 1'b0;
                        end
                    end
                end
            end

            // Backpressure to arbitration: output can accept if register can accept
            assign m_tready = m_can_accept;
        end else begin : gen_m_no_reg
            assign m_axis_tvalid = m_tvalid;
            assign m_axis_tlast = m_tlast;
            assign m_axis_tdata = m_tdata;
            assign m_axis_tkeep = m_tkeep;
            assign m_axis_tid = m_tid;
            assign m_axis_tdest = m_tdest;
            assign m_axis_tuser = m_tuser;
            assign m_tready = m_axis_tready;
        end
    endgenerate

    // Source ready: a source can be ready if any output that it can connect to is ready
    // and has selected this source
    generate
        for (s = 0; s < S_COUNT; s = s + 1) begin : gen_s_ready
            wire any_output_ready;
            genvar k;
            for (k = 0; k < M_COUNT; k = k + 1) begin : gen_s_ready_m
                // Source s is ready if output k has granted to s and output k is ready
                wire grant_to_s = (grant[k] != 0) && (grant_idx[k] == s);
                wire out_ready = m_tready[k];
                // We need to OR all such conditions
            end
            
            // Compute any_output_ready
            assign any_output_ready = |({M_COUNT{1'b0}} & {M_COUNT{1'b0}}); // Placeholder
            
            // Let's compute it properly
            wire [M_COUNT-1:0] ready_for_s;
            for (k = 0; k < M_COUNT; k = k + 1) begin : gen_ready_for_s
                assign ready_for_s[k] = (grant[k] != 0) && (grant_idx[k] == s) && m_tready[k];
            end
            assign any_output_ready = |ready_for_s;
            
            assign s_tready[s] = any_output_ready;
        end
    endgenerate

endmodule
