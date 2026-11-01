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
    wire [S_COUNT*DATA_WIDTH-1:0] s_tdata_int;
    wire [S_COUNT*KEEP_WIDTH-1:0] s_tkeep_int;
    wire [S_COUNT*S_ID_WIDTH-1:0] s_tid_int;
    wire [S_COUNT*S_DEST_WIDTH-1:0] s_tdest_int;
    wire [S_COUNT*USER_WIDTH-1:0] s_tuser_int;

    // Source register stage
    generate
        if (S_REG_TYPE != 0) begin : gen_s_reg
            reg [S_COUNT-1:0] s_tvalid_reg;
            reg [S_COUNT-1:0] s_tlast_reg;
            reg [S_COUNT*DATA_WIDTH-1:0] s_tdata_reg;
            reg [S_COUNT*KEEP_WIDTH-1:0] s_tkeep_reg;
            reg [S_COUNT*S_ID_WIDTH-1:0] s_tid_reg;
            reg [S_COUNT*S_DEST_WIDTH-1:0] s_tdest_reg;
            reg [S_COUNT*USER_WIDTH-1:0] s_tuser_reg;

            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    s_tvalid_reg <= {S_COUNT{1'b0}};
                    s_tlast_reg <= {S_COUNT{1'b0}};
                    s_tdata_reg <= {S_COUNT*DATA_WIDTH{1'b0}};
                    s_tkeep_reg <= {S_COUNT*KEEP_WIDTH{1'b0}};
                    s_tid_reg <= {S_COUNT*S_ID_WIDTH{1'b0}};
                    s_tdest_reg <= {S_COUNT*S_DEST_WIDTH{1'b0}};
                    s_tuser_reg <= {S_COUNT*USER_WIDTH{1'b0}};
                end else begin
                    for (genvar i = 0; i < S_COUNT; i = i + 1) begin : gen_s_reg_i
                        if (s_axis_tvalid[i] && s_tready_int[i]) begin
                            s_tvalid_reg[i] <= 1'b1;
                            s_tlast_reg[i] <= s_axis_tlast[i];
                            s_tdata_reg[i*DATA_WIDTH +: DATA_WIDTH] <= s_axis_tdata[i*DATA_WIDTH +: DATA_WIDTH];
                            s_tkeep_reg[i*KEEP_WIDTH +: KEEP_WIDTH] <= s_axis_tkeep[i*KEEP_WIDTH +: KEEP_WIDTH];
                            s_tid_reg[i*S_ID_WIDTH +: S_ID_WIDTH] <= s_axis_tid[i*S_ID_WIDTH +: S_ID_WIDTH];
                            s_tdest_reg[i*S_DEST_WIDTH +: S_DEST_WIDTH] <= s_axis_tdest[i*S_DEST_WIDTH +: S_DEST_WIDTH];
                            s_tuser_reg[i*USER_WIDTH +: USER_WIDTH] <= s_axis_tuser[i*USER_WIDTH +: USER_WIDTH];
                        end else if (s_tvalid_reg[i] && s_tready_int[i]) begin
                            s_tvalid_reg[i] <= 1'b0;
                        end
                    end
                end
            end

            assign s_tvalid_int = s_tvalid_reg;
            assign s_tlast_int = s_tlast_reg;
            assign s_tdata_int = s_tdata_reg;
            assign s_tkeep_int = s_tkeep_reg;
            assign s_tid_int = s_tid_reg;
            assign s_tdest_int = s_tdest_reg;
            assign s_tuser_int = s_tuser_reg;
            assign s_axis_tready = s_tvalid_reg | s_tready_int;
        end else begin : gen_s_no_reg
            assign s_tvalid_int = s_axis_tvalid;
            assign s_tlast_int = s_axis_tlast;
            assign s_tdata_int = s_axis_tdata;
            assign s_tkeep_int = s_axis_tkeep;
            assign s_tid_int = s_axis_tid;
            assign s_tdest_int = s_axis_tdest;
            assign s_tuser_int = s_axis_tuser;
            assign s_axis_tready = s_tready_int;
        end
    endgenerate

    // Per-source state: track if we're in a packet
    reg [S_COUNT-1:0] s_in_packet;

    // Determine which source is active for each destination
    // For each destination m, find which source s is currently sending to it
    // A source s is "active" for destination m if:
    //   - s_tvalid_int[s] is high
    //   - s_tdest_int[s] points to m (or m is within the range specified by tdest)
    //   - s_in_packet[s] is high (we're in the middle of a packet)
    //   - OR this is the first beat of a new packet (s_in_packet[s] is low but tvalid is high)

    // Actually, let's think about this differently.
    // Each source has a destination. When a source starts a packet (first beat),
    // it claims a destination. It continues to that destination until tlast.
    // We need to track which source owns which destination.

    // Let's use a simpler approach:
    // For each destination m, we track which source is currently sending to it.
    // If no source is currently sending, we can accept a new packet from any source
    // that wants to send to m.

    reg [S_COUNT-1:0] dest_owner [0:M_COUNT-1]; // Which source owns each destination
    reg [M_COUNT-1:0] dest_busy;                // Which destinations are busy

    // For each source, determine its target destination
    wire [S_COUNT-1:0] s_has_valid;
    wire [S_COUNT*S_DEST_WIDTH-1:0] s_tdest_flat;
    
    assign s_has_valid = s_tvalid_int;
    assign s_tdest_flat = s_tdest_int;

    // Determine if a source is starting a new packet
    wire [S_COUNT-1:0] s_start_packet;
    assign s_start_packet = s_has_valid & ~s_in_packet;

    // Determine if a source is continuing a packet
    wire [S_COUNT-1:0] s_continue_packet;
    assign s_continue_packet = s_has_valid & s_in_packet;

    // For each destination, determine which source is trying to send to it
    // A source s sends to destination m if:
    //   - s is starting a packet and s_tdest[s] == m
    //   - s is continuing a packet and dest_owner[m] == s

    // Let's build a matrix: src_to_dest[s][m] = 1 if source s is sending to destination m
    wire [S_COUNT-1:0] src_to_dest [0:M_COUNT-1];

    generate
        for (genvar m = 0; m < M_COUNT; m = m + 1) begin : gen_dest
            assign src_to_dest[m] = {S_COUNT{1'b0}};
            for (genvar s = 0; s < S_COUNT; s = s + 1) begin : gen_src
                wire is_start = s_start_packet[s] & (s_tdest_int[s*S_DEST_WIDTH +: S_DEST_WIDTH] == m[S_DEST_WIDTH-1:0]);
                wire is_cont = s_continue_packet[s] & (dest_owner[m] == s[S_COUNT-1:0]);
                assign src_to_dest[m][s] = is_start | is_cont;
            end
        end
    endgenerate

    // Arbitration: for each destination, select one source
    // If ARB_TYPE_ROUND_ROBIN, use round-robin
    // If ARB_LSB_HIGH_PRIORITY, use LSB priority

    wire [S_COUNT-1:0] arb_winner [0:M_COUNT-1];
    reg [S_COUNT-1:0] rr_ptr [0:M_COUNT-1];

    generate
        for (genvar m = 0; m < M_COUNT; m = m + 1) begin : gen_arb
            if (ARB_TYPE_ROUND_ROBIN) begin : gen_rr
                // Round-robin arbitration
                wire [S_COUNT-1:0] candidates = src_to_dest[m];
                wire [S_COUNT-1:0] rr_ptr_val = rr_ptr[m];
                
                // Rotate candidates so that rr_ptr is at position 0
                wire [2*S_COUNT-1:0] rotated = {candidates, candidates};
                wire [S_COUNT-1:0] rotated_cand = rotated[rr_ptr_val +: S_COUNT];
                
                // Find first set bit
                wire [S_COUNT-1:0] winner_rotated;
                assign winner_rotated = rotated_cand & ~(rotated_cand - 1'b1);
                
                // Rotate back
                wire [2*S_COUNT-1:0] rotated_winner = {winner_rotated, winner_rotated};
                wire [S_COUNT-1:0] winner = rotated_winner[(S_COUNT - rr_ptr_val) +: S_COUNT];
                
                assign arb_winner[m] = winner;
                
                always @(posedge clk or posedge rst) begin
                    if (rst) begin
                        rr_ptr[m] <= {S_COUNT{1'b0}};
                    end else if (arb_winner[m] != {S_COUNT{1'b0}}) begin
                        // Advance pointer to next source after winner
                        rr_ptr[m] <= arb_winner[m] + 1'b1;
                    end
                end
            end else begin : gen_lsb
                // LSB high priority: lowest index wins
                wire [S_COUNT-1:0] candidates = src_to_dest[m];
                wire [S_COUNT-1:0] winner = candidates & ~(candidates - 1'b1);
                assign arb_winner[m] = winner;
            end
        end
    endgenerate

    // Determine which source is selected for each destination
    wire [S_COUNT-1:0] selected_src [0:M_COUNT-1];
    generate
        for (genvar m = 0; m < M_COUNT; m = m + 1) begin : gen_sel
            assign selected_src[m] = arb_winner[m];
        end
    endgenerate

    // Determine if a destination is ready to accept data
    wire [M_COUNT-1:0] m_ready;
    assign m_ready = m_axis_tready;

    // Determine if a source can be accepted
    // A source s can be accepted if:
    //   - It is selected for some destination m
    //   - That destination m is ready
    wire [S_COUNT-1:0] s_accepted;
    assign s_accepted = {S_COUNT{1'b0}};
    
    generate
        for (genvar s = 0; s < S_COUNT; s = s + 1) begin : gen_acc
            wire accepted = 1'b0;
            for (genvar m = 0; m < M_COUNT; m = m + 1) begin : gen_acc_m
                wire sel = selected_src[m][s];
                wire ready = m_ready[m];
                wire conn = M_CONNECT[m*S_COUNT + s];
                accepted = accepted | (sel & ready & conn);
            end
            assign s_accepted[s] = accepted;
        end
    endgenerate

    // Source ready signal
    assign s_tready_int = s_accepted;

    // Update source in-packet state
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_in_packet <= {S_COUNT{1'b0}};
        end else begin
            for (genvar s = 0; s < S_COUNT; s = s + 1) begin : gen_pkt
                if (s_accepted[s]) begin
                    if (s_tlast_int[s]) begin
                        s_in_packet[s] <= 1'b0;
                    end else begin
                        s_in_packet[s] <= 1'b1;
                    end
                end
            end
        end
    end

    // Update destination owner state
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (genvar m = 0; m < M_COUNT; m = m + 1) begin : gen_own
                dest_owner[m] <= {S_COUNT{1'b0}};
            end
            dest_busy <= {M_COUNT{1'b0}};
        end else begin
            for (genvar m = 0; m < M_COUNT; m = m + 1) begin : gen_own2
                if (m_ready[m] && arb_winner[m] != {S_COUNT{1'b0}}) begin
                    // Find which source won
                    for (genvar s = 0; s < S_COUNT; s = s + 1) begin : gen_own3
                        if (arb_winner[m][s]) begin
                            dest_owner[m] <= s[S_COUNT-1:0];
                        end
                    end
                    if (s_tlast_int[arb_winner[m] != {S_COUNT{1'b0}} ? 0 : 0]) begin
                        // This is tricky, let's handle it differently
                    end
                end
            end
        end
    end

    // Let me redo the destination owner update more carefully
    // We need to know which source won for each destination, and whether that source's beat is tlast

    wire [S_COUNT-1:0] winner_src_idx [0:M_COUNT-1];
    generate
        for (genvar m = 0; m < M_COUNT; m = m + 1) begin : gen_widx
            wire [S_COUNT-1:0] w = arb_winner[m];
            wire [S_COUNT-1:0] w_onehot = w & ~(w - 1'b1);
            // Convert one-hot to index
            wire [S_COUNT-1:0] idx;
            assign idx = w_onehot[0] ? 0[S_COUNT-1:0] :
                         w_onehot[1] ? 1[S_COUNT-1:0] :
                         w_onehot[2] ? 2[S_COUNT-1:0] :
                         w_onehot[3] ? 3[S_COUNT-1:0] :
                         w_onehot[4] ? 4[S_COUNT-1:0] :
                         w_onehot[5] ? 5[S_COUNT-1:0] :
                         w_onehot[6] ? 6[S_COUNT-1:0] :
                         w_onehot[7] ? 7[S_COUNT-1:0] :
                         w_onehot[8] ? 8[S_COUNT-1:0] :
                         w_onehot[9] ? 9[S_COUNT-1:0] :
                         w_onehot[10] ? 10[S_COUNT-1:0] :
                         w_onehot[11] ? 11[S_COUNT-1:0] :
                         w_onehot[12] ? 12[S_COUNT-1:0] :
                         w_onehot[13] ? 13[S_COUNT-1:0] :
                         w_onehot[14] ? 14[S_COUNT-1:0] :
                         w_onehot[15] ? 15[S_COUNT-1:0] :
                         {S_COUNT{1'b0}};
            assign winner_src_idx[m] = idx;
        end
    endgenerate

    // Simplified: just use the one-hot directly
    wire [S_COUNT-1:0] winner_onehot [0:M_COUNT-1];
    generate
        for (genvar m = 0; m < M_COUNT; m = m + 1) begin : gen_woh
            assign winner_onehot[m] = arb_winner[m];
        end
    endgenerate

    // Update dest_owner and dest_busy
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (genvar m = 0; m < M_COUNT; m = m + 1) begin : gen_own_rst
                dest_owner[m] <= {S_COUNT{1'b0}};
            end
            dest_busy <= {M_COUNT{1'b0}};
        end else begin
            for (genvar m = 0; m < M_COUNT; m = m + 1) begin : gen_own_upd
                if (m_ready[m] && arb_winner[m] != {S_COUNT{1'b0}}) begin
                    // Find the winning source index
                    for (genvar s = 0; s < S_COUNT; s = s + 1) begin : gen_own_s
                        if (arb_winner[m][s]) begin
                            dest_owner[m] <= s[S_COUNT-1:0];
                        end
                    end
                    // Check if this beat is tlast
                    for (genvar s = 0; s < S_COUNT; s = s + 1) begin : gen_own_tlast
                        if (arb_winner[m][s] && s_tlast_int[s]) begin
                            dest_busy[m] <= 1'b0;
                        end else if (arb_winner[m][s] && !s_tlast_int[s]) begin
                            dest_busy[m] <= 1'b1;
                        end
                    end
                end
            end
        end
    end

    // Output muxing
    generate
        for (genvar m = 0; m < M_COUNT; m = m + 1) begin : gen_out
            wire [S_COUNT-1:0] w = arb_winner[m];
            wire has_winner = (w != {S_COUNT{1'b0}});
            
            // Mux data
            wire [DATA_WIDTH-1:0] out_data;
            assign out_data = w[0] ? s_tdata_int[0*DATA_WIDTH +: DATA_WIDTH] :
                               w[1] ? s_tdata_int[1*DATA_WIDTH +: DATA_WIDTH] :
                               w[2] ? s_tdata_int[2*DATA_WIDTH +: DATA_WIDTH] :
                               w[3] ? s_tdata_int[3*DATA_WIDTH +: DATA_WIDTH] :
                               w[4] ? s_tdata_int[4*DATA_WIDTH +: DATA_WIDTH] :
                               w[5] ? s_tdata_int[5*DATA_WIDTH +: DATA_WIDTH] :
                               w[6] ? s_tdata_int[6*DATA_WIDTH +: DATA_WIDTH] :
                               w[7] ? s_tdata_int[7*DATA_WIDTH +: DATA_WIDTH] :
                               w[8] ? s_tdata_int[8*DATA_WIDTH +: DATA_WIDTH] :
                               w[9] ? s_tdata_int[9*DATA_WIDTH +: DATA_WIDTH] :
                               w[10] ? s_tdata_int[10*DATA_WIDTH +: DATA_WIDTH] :
                               w[11] ? s_tdata_int[11*DATA_WIDTH +: DATA_WIDTH] :
                               w[12] ? s_tdata_int[12*DATA_WIDTH +: DATA_WIDTH] :
                               w[13] ? s_tdata_int[13*DATA_WIDTH +: DATA_WIDTH] :
                               w[14] ? s_tdata_int[14*DATA_WIDTH +: DATA_WIDTH] :
                               w[15] ? s_tdata_int[15*DATA_WIDTH +: DATA_WIDTH] :
                               {DATA_WIDTH{1'b0}};
            
            assign m_axis_tdata[m*DATA_WIDTH +: DATA_WIDTH] = out_data;
            
            // Mux tkeep
            wire [KEEP_WIDTH-1:0] out_keep;
            assign out_keep = w[0] ? s_tkeep_int[0*KEEP_WIDTH +: KEEP_WIDTH] :
                               w[1] ? s_tkeep_int[1*KEEP_WIDTH +: KEEP_WIDTH] :
                               w[2] ? s_tkeep_int[2*KEEP_WIDTH +: KEEP_WIDTH] :
                               w[3] ? s_tkeep_int[3*KEEP_WIDTH +: KEEP_WIDTH] :
                               w[4] ? s_tkeep_int[4*KEEP_WIDTH +: KEEP_WIDTH] :
                               w[5] ? s_tkeep_int[5*KEEP_WIDTH +: KEEP_WIDTH] :
                               w[6] ? s_tkeep_int[6*KEEP_WIDTH +: KEEP_WIDTH] :
                               w[7] ? s_tkeep_int[7*KEEP_WIDTH +: KEEP_WIDTH] :
                               w[8] ? s_tkeep_int[8*KEEP_WIDTH +: KEEP_WIDTH] :
                               w[9] ? s_tkeep_int[9*KEEP_WIDTH +: KEEP_WIDTH] :
                               w[10] ? s_tkeep_int[10*KEEP_WIDTH +: KEEP_WIDTH] :
                               w[11] ? s_tkeep_int[11*KEEP_WIDTH +: KEEP_WIDTH] :
                               w[12] ? s_tkeep_int[12*KEEP_WIDTH +: KEEP_WIDTH] :
                               w[13] ? s_tkeep_int[13*KEEP_WIDTH +: KEEP_WIDTH] :
                               w[14] ? s_tkeep_int[14*KEEP_WIDTH +: KEEP_WIDTH] :
                               w[15] ? s_tkeep_int[15*KEEP_WIDTH +: KEEP_WIDTH] :
                               {KEEP_WIDTH{1'b0}};
            
            assign m_axis_tkeep[m*KEEP_WIDTH +: KEEP_WIDTH] = out_keep;
            
            // Mux tlast
            wire out_last;
            assign out_last = w[0] ? s_tlast_int[0] :
                              w[1] ? s_tlast_int[1] :
                              w[2] ? s_tlast_int[2] :
                              w[3] ? s_tlast_int[3] :
                              w[4] ? s_tlast_int[4] :
                              w[5] ? s_tlast_int[5] :
                              w[6] ? s_tlast_int[6] :
                              w[7] ? s_tlast_int[7] :
                              w[8] ? s_tlast_int[8] :
                              w[9] ? s_tlast_int[9] :
                              w[10] ? s_tlast_int[10] :
                              w[11] ? s_tlast_int[11] :
                              w[12] ? s_tlast_int[12] :
                              w[13] ? s_tlast_int[13] :
                              w[14] ? s_tlast_int[14] :
                              w[15] ? s_tlast_int[15] :
                              1'b0;
            
            assign m_axis_tlast[m] = out_last;
            
            // Mux tid
            wire [S_ID_WIDTH-1:0] out_tid;
            assign out_tid = w[0] ? s_tid_int[0*S_ID_WIDTH +: S_ID_WIDTH] :
                              w[1] ? s_tid_int[1*S_ID_WIDTH +: S_ID_WIDTH] :
                              w[2] ? s_tid_int[2*S_ID_WIDTH +: S_ID_WIDTH] :
                              w[3] ? s_tid_int[3*S_ID_WIDTH +: S_ID_WIDTH] :
                              w[4] ? s_tid_int[4*S_ID_WIDTH +: S_ID_WIDTH] :
                              w[5] ? s_tid_int[5*S_ID_WIDTH +: S_ID_WIDTH] :
                              w[6] ? s_tid_int[6*S_ID_WIDTH +: S_ID_WIDTH] :
                              w[7] ? s_tid_int[7*S_ID_WIDTH +: S_ID_WIDTH] :
                              w[8] ? s_tid_int[8*S_ID_WIDTH +: S_ID_WIDTH] :
                              w[9] ? s_tid_int[9*S_ID_WIDTH +: S_ID_WIDTH] :
                              w[10] ? s_tid_int[10*S_ID_WIDTH +: S_ID_WIDTH] :
                              w[11] ? s_tid_int[11*S_ID_WIDTH +: S_ID_WIDTH] :
                              w[12] ? s_tid_int[12*S_ID_WIDTH +: S_ID_WIDTH] :
                              w[13] ? s_tid_int[13*S_ID_WIDTH +: S_ID_WIDTH] :
                              w[14] ? s_tid_int[14*S_ID_WIDTH +: S_ID_WIDTH] :
                              w[15] ? s_tid_int[15*S_ID_WIDTH +: S_ID_WIDTH] :
                              {S_ID_WIDTH{1'b0}};
            
            // Mux tuser
            wire [USER_WIDTH-1:0] out_user;
            assign out_user = w[0] ? s_tuser_int[0*USER_WIDTH +: USER_WIDTH] :
                               w[1] ? s_tuser_int[1*USER_WIDTH +: USER_WIDTH] :
                               w[2] ? s_tuser_int[2*USER_WIDTH +: USER_WIDTH] :
                               w[3] ? s_tuser_int[3*USER_WIDTH +: USER_WIDTH] :
                               w[4] ? s_tuser_int[4*USER_WIDTH +: USER_WIDTH] :
                               w[5] ? s_tuser_int[5*USER_WIDTH +: USER_WIDTH] :
                               w[6] ? s_tuser_int[6*USER_WIDTH +: USER_WIDTH] :
                               w[7] ? s_tuser_int[7*USER_WIDTH +: USER_WIDTH] :
                               w[8] ? s_tuser_int[8*USER_WIDTH +: USER_WIDTH] :
                               w[9] ? s_tuser_int[9*USER_WIDTH +: USER_WIDTH] :
                               w[10] ? s_tuser_int[10*USER_WIDTH +: USER_WIDTH] :
                               w[11] ? s_tuser_int[11*USER_WIDTH +: USER_WIDTH] :
                               w[12] ? s_tuser_int[12*USER_WIDTH +: USER_WIDTH] :
                               w[13] ? s_tuser_int[13*USER_WIDTH +: USER_WIDTH] :
                               w[14] ? s_tuser_int[14*USER_WIDTH +: USER_WIDTH] :
                               w[15] ? s_tuser_int[15*USER_WIDTH +: USER_WIDTH] :
                               {USER_WIDTH{1'b0}};
            
            assign m_axis_tuser[m*USER_WIDTH +: USER_WIDTH] = out_user;
            
            // Output valid
            assign m_axis_tvalid[m] = has_winner & m_ready[m];
            
            // Output tid with source ID appended if UPDATE_TID
            if (UPDATE_TID) begin : gen_tid_upd
                wire [M_ID_WIDTH-1:0] out_tid_full;
                assign out_tid_full[S_ID_WIDTH-1:0] = out_tid;
                assign out_tid_full[M_ID_WIDTH-1:S_ID_WIDTH] = dest_owner[m][M_ID_WIDTH-S_ID_WIDTH-1:0];
                assign m_axis_tid[m*M_ID_WIDTH +: M_ID_WIDTH] = out_tid_full;
            end else begin : gen_tid_no_upd
                assign m_axis_tid[m*M_ID_WIDTH +: M_ID_WIDTH] = {M_ID_WIDTH-S_ID_WIDTH{1'b0}, out_tid};
            end
            
            // Output tdest
            assign m_axis_tdest[m*M_DEST_WIDTH +: M_DEST_WIDTH] = m[M_DEST_WIDTH-1:0];
        end
    endgenerate

endmodule
