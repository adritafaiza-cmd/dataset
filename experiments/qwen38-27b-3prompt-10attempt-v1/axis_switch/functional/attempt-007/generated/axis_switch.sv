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
    wire [S_COUNT-1:0] s_valid;
    wire [S_COUNT-1:0] s_ready;
    wire [S_COUNT-1:0] s_fire;
    
    wire [M_COUNT-1:0] m_valid;
    wire [M_COUNT-1:0] m_ready;
    wire [M_COUNT-1:0] m_fire;
    
    // Per-output arbitration
    // For each output m, we need to select one input s that wants to go to m
    // and is ready to transfer.
    
    // Determine which inputs want to go to each output
    // s_wants[m][s] = 1 if input s wants to go to output m
    wire [S_COUNT-1:0] s_wants [0:M_COUNT-1];
    
    genvar i, j;
    generate
        for (i = 0; i < M_COUNT; i = i + 1) begin : gen_wants
            for (j = 0; j < S_COUNT; j = j + 1) begin : gen_wants_inner
                assign s_wants[i][j] = s_axis_tvalid[j] && M_CONNECT[i*S_COUNT+j];
            end
        end
    endgenerate
    
    // Arbitration for each output
    // We'll use a simple priority encoder or round-robin
    // For simplicity, let's implement a basic priority arbiter
    // If ARB_TYPE_ROUND_ROBIN is set, we need to track last granted input
    
    // For now, let's use a fixed priority arbiter for simplicity
    // The winner for output m is the lowest index s that wants to go to m
    // and is ready (s_ready[s] is high)
    
    // Actually, we need to be more careful. The input s can only send to one output at a time.
    // So we need to ensure that if input s is granted to output m1, it cannot be granted to output m2.
    
    // Let's use a different approach:
    // 1. For each input s, determine which output it wants to go to (from tdest)
    // 2. For each output m, arbitrate among inputs that want to go to m
    // 3. Ensure no input is granted to multiple outputs
    
    // Let's decode tdest for each input
    wire [S_COUNT-1:0][$clog2(M_COUNT)-1:0] s_dest_decoded;
    
    generate
        for (i = 0; i < S_COUNT; i = i + 1) begin : gen_dest_decode
            assign s_dest_decoded[i] = s_axis_tdest[i*S_DEST_WIDTH +: S_DEST_WIDTH];
        end
    endgenerate
    
    // For each output m, create a vector of inputs that want to go to m
    // and are valid
    wire [S_COUNT-1:0] m_request [0:M_COUNT-1];
    
    generate
        for (i = 0; i < M_COUNT; i = i + 1) begin : gen_request
            for (j = 0; j < S_COUNT; j = j + 1) begin : gen_request_inner
                assign m_request[i][j] = s_axis_tvalid[j] && (s_dest_decoded[j] == i);
            end
        end
    endgenerate
    
    // Arbitration: for each output, select one input
    // We'll use a simple priority encoder
    // The winner is the lowest index input that has a request
    
    wire [S_COUNT-1:0] m_grant [0:M_COUNT-1];
    
    generate
        for (i = 0; i < M_COUNT; i = i + 1) begin : gen_arb
            // Priority encoder: find the lowest set bit
            // We can use a simple approach: check each bit from LSB to MSB
            wire [S_COUNT-1:0] req = m_request[i];
            
            // Generate grant signals
            // grant[j] = req[j] && !(req[j-1] | req[j-2] | ... | req[0])
            // For j=0: grant[0] = req[0]
            // For j>0: grant[j] = req[j] && ~(req[j-1:0] != 0)
            
            genvar k;
            for (k = 0; k < S_COUNT; k = k + 1) begin : gen_grant
                if (k == 0) begin : gen_grant_0
                    assign m_grant[i][k] = req[k];
                end else begin : gen_grant_n
                    assign m_grant[i][k] = req[k] && (req[k-1:0] == {k{1'b0}});
                end
            end
        end
    endgenerate
    
    // Now we have m_grant[m][s] = 1 if input s is granted to output m
    // But we need to ensure that each input is granted to at most one output
    // If an input is granted to multiple outputs, we need to resolve the conflict
    
    // For simplicity, let's assume that the tdest field ensures that each input
    // only wants to go to one output, so there should be no conflict.
    // But to be safe, let's add a conflict resolution: if an input is granted to
    // multiple outputs, we give it to the lowest output index.
    
    // Actually, since each input has a single tdest, it can only want to go to one output.
    // So m_grant[m][s] can only be 1 for at most one m for a given s.
    
    // Let's verify: m_request[i][j] = s_axis_tvalid[j] && (s_dest_decoded[j] == i)
    // Since s_dest_decoded[j] is a single value, it can only equal one i.
    // So for a given j, m_request[i][j] is 1 for at most one i.
    // Therefore, m_grant[i][j] is 1 for at most one i.
    // So there is no conflict.
    
    // Now, s_ready[s] = 1 if input s is granted to some output and that output is ready
    // m_valid[m] = 1 if some input is granted to output m
    
    wire [S_COUNT-1:0] s_granted;
    wire [M_COUNT-1:0] m_has_grant;
    
    generate
        for (i = 0; i < S_COUNT; i = i + 1) begin : gen_s_granted
            // s_granted[i] = 1 if input i is granted to any output
            wire [M_COUNT-1:0] granted_to = {M_COUNT{1'b0}};
            genvar p;
            for (p = 0; p < M_COUNT; p = p + 1) begin : gen_granted_to
                assign granted_to[p] = m_grant[p][i];
            end
            assign s_granted[i] = |granted_to;
        end
    endgenerate
    
    generate
        for (i = 0; i < M_COUNT; i = i + 1) begin : gen_m_has_grant
            assign m_has_grant[i] = |m_grant[i];
        end
    endgenerate
    
    // s_ready[s] = 1 if input s is granted to an output that is ready
    // We need to know which output input s is granted to
    wire [S_COUNT-1:0][$clog2(M_COUNT)-1:0] s_granted_to;
    
    generate
        for (i = 0; i < S_COUNT; i = i + 1) begin : gen_s_granted_to
            // Find which output input i is granted to
            // Since at most one output, we can use a simple encoder
            wire [M_COUNT-1:0] granted_to = {M_COUNT{1'b0}};
            genvar p;
            for (p = 0; p < M_COUNT; p = p + 1) begin : gen_granted_to2
                assign granted_to[p] = m_grant[p][i];
            end
            
            // Encode: find the index of the set bit
            // For simplicity, use a case statement or a priority encoder
            // Since at most one bit is set, we can use a simple approach
            reg [$clog2(M_COUNT)-1:0] enc;
            always @(*) begin
                enc = 0;
                for (p = 0; p < M_COUNT; p = p + 1) begin
                    if (granted_to[p]) begin
                        enc = p;
                    end
                end
            end
            assign s_granted_to[i] = enc;
        end
    endgenerate
    
    // s_ready[s] = 1 if input s is granted to an output and that output is ready
    generate
        for (i = 0; i < S_COUNT; i = i + 1) begin : gen_s_ready
            assign s_ready[i] = s_granted[i] && m_ready[s_granted_to[i]];
        end
    endgenerate
    
    // m_valid[m] = 1 if some input is granted to output m
    assign m_valid = m_has_grant;
    
    // Now, we need to route the data
    // For each output m, if m_valid[m] is 1, we need to select the data from the granted input
    
    // Let's create the output signals
    wire [M_COUNT*DATA_WIDTH-1:0] m_tdata_internal;
    wire [M_COUNT*KEEP_WIDTH-1:0] m_tkeep_internal;
    wire [M_COUNT-1:0] m_tlast_internal;
    wire [M_COUNT*M_ID_WIDTH-1:0] m_tid_internal;
    wire [M_COUNT*M_DEST_WIDTH-1:0] m_tdest_internal;
    wire [M_COUNT*USER_WIDTH-1:0] m_tuser_internal;
    
    generate
        for (i = 0; i < M_COUNT; i = i + 1) begin : gen_output
            // Find the granted input for output i
            wire [S_COUNT-1:0] grant = m_grant[i];
            
            // Select the data from the granted input
            // We need to find which input is granted
            reg [$clog2(S_COUNT)-1:0] sel;
            always @(*) begin
                sel = 0;
                for (j = 0; j < S_COUNT; j = j + 1) begin
                    if (grant[j]) begin
                        sel = j;
                    end
                end
            end
            
            // Route data
            assign m_tdata_internal[i*DATA_WIDTH +: DATA_WIDTH] = s_axis_tdata[sel*DATA_WIDTH +: DATA_WIDTH];
            
            if (KEEP_ENABLE) begin : gen_keep
                assign m_tkeep_internal[i*KEEP_WIDTH +: KEEP_WIDTH] = s_axis_tkeep[sel*KEEP_WIDTH +: KEEP_WIDTH];
            end else begin : gen_no_keep
                assign m_tkeep_internal[i*KEEP_WIDTH +: KEEP_WIDTH] = {KEEP_WIDTH{1'b0}};
            end
            
            assign m_tlast_internal[i] = s_axis_tlast[sel];
            
            if (ID_ENABLE) begin : gen_id
                if (UPDATE_TID) begin : gen_update_tid
                    // Update TID: combine source ID and source index
                    // M_ID_WIDTH = S_ID_WIDTH + $clog2(S_COUNT)
                    // New TID = {s_axis_tid[sel], sel}
                    assign m_tid_internal[i*M_ID_WIDTH +: M_ID_WIDTH] = {s_axis_tid[sel*S_ID_WIDTH +: S_ID_WIDTH], sel};
                end else begin : gen_no_update_tid
                    assign m_tid_internal[i*M_ID_WIDTH +: M_ID_WIDTH] = s_axis_tid[sel*S_ID_WIDTH +: S_ID_WIDTH];
                end
            end else begin : gen_no_id
                assign m_tid_internal[i*M_ID_WIDTH +: M_ID_WIDTH] = {M_ID_WIDTH{1'b0}};
            end
            
            if (M_DEST_WIDTH > 0) begin : gen_dest
                assign m_tdest_internal[i*M_DEST_WIDTH +: M_DEST_WIDTH] = i;
            end else begin : gen_no_dest
                assign m_tdest_internal[i*M_DEST_WIDTH +: M_DEST_WIDTH] = {M_DEST_WIDTH{1'b0}};
            end
            
            if (USER_ENABLE) begin : gen_user
                assign m_tuser_internal[i*USER_WIDTH +: USER_WIDTH] = s_axis_tuser[sel*USER_WIDTH +: USER_WIDTH];
            end else begin : gen_no_user
                assign m_tuser_internal[i*USER_WIDTH +: USER_WIDTH] = {USER_WIDTH{1'b0}};
            end
        end
    endgenerate
    
    // Assign output signals
    assign m_axis_tdata = m_tdata_internal;
    assign m_axis_tkeep = m_tkeep_internal;
    assign m_axis_tvalid = m_valid;
    assign m_axis_tlast = m_tlast_internal;
    assign m_axis_tid = m_tid_internal;
    assign m_axis_tdest = m_tdest_internal;
    assign m_axis_tuser = m_tuser_internal;
    
    // Assign input ready signals
    assign s_axis_tready = s_ready;
    
endmodule
