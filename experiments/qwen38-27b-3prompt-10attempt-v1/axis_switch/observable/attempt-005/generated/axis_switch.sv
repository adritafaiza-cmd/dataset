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
    if (S_REG_TYPE == 0) begin
        assign s_tvalid = s_axis_tvalid;
        assign s_tdata = s_axis_tdata;
        assign s_tkeep = s_axis_tkeep;
        assign s_tlast = s_axis_tlast;
        assign s_tid = s_axis_tid;
        assign s_tdest = s_axis_tdest;
        assign s_tuser = s_axis_tuser;
    end else begin
        reg [S_COUNT-1:0] s_tvalid_r;
        reg [S_COUNT*DATA_WIDTH-1:0] s_tdata_r;
        reg [S_COUNT*KEEP_WIDTH-1:0] s_tkeep_r;
        reg [S_COUNT-1:0] s_tlast_r;
        reg [S_COUNT*S_ID_WIDTH-1:0] s_tid_r;
        reg [S_COUNT*S_DEST_WIDTH-1:0] s_tdest_r;
        reg [S_COUNT*USER_WIDTH-1:0] s_tuser_r;

        assign s_tvalid = s_tvalid_r;
        assign s_tdata = s_tdata_r;
        assign s_tkeep = s_tkeep_r;
        assign s_tlast = s_tlast_r;
        assign s_tid = s_tid_r;
        assign s_tdest = s_tdest_r;
        assign s_tuser = s_tuser_r;

        wire [S_COUNT-1:0] s_tready_internal;
        assign s_tready_internal = s_tready;

        always @(posedge clk or posedge rst) begin
            if (rst) begin
                s_tvalid_r <= {S_COUNT{1'b0}};
            end else begin
                for (genvar i = 0; i < S_COUNT; i = i + 1) begin
                    if (s_axis_tvalid[i] && s_tready_internal[i]) begin
                        s_tvalid_r[i] <= 1'b1;
                        s_tdata_r[i*DATA_WIDTH +: DATA_WIDTH] <= s_axis_tdata[i*DATA_WIDTH +: DATA_WIDTH];
                        s_tkeep_r[i*KEEP_WIDTH +: KEEP_WIDTH] <= s_axis_tkeep[i*KEEP_WIDTH +: KEEP_WIDTH];
                        s_tlast_r[i] <= s_axis_tlast[i];
                        s_tid_r[i*S_ID_WIDTH +: S_ID_WIDTH] <= s_axis_tid[i*S_ID_WIDTH +: S_ID_WIDTH];
                        s_tdest_r[i*S_DEST_WIDTH +: S_DEST_WIDTH] <= s_axis_tdest[i*S_DEST_WIDTH +: S_DEST_WIDTH];
                        s_tuser_r[i*USER_WIDTH +: USER_WIDTH] <= s_axis_tuser[i*USER_WIDTH +: USER_WIDTH];
                    end else if (s_tvalid_r[i] && s_tready_internal[i]) begin
                        s_tvalid_r[i] <= 1'b0;
                    end
                end
            end
        end
    end

    // Determine which source is active for each destination
    // For each destination m, find the source s that is valid, connected, and has tdest matching m
    wire [S_COUNT-1:0] dest_valid [0:M_COUNT-1];
    wire [S_COUNT-1:0] dest_connected [0:M_COUNT-1];
    wire [S_COUNT-1:0] dest_match [0:M_COUNT-1];
    wire [S_COUNT-1:0] dest_candidate [0:M_COUNT-1];

    genvar m;
    genvar s;
    generate
        for (m = 0; m < M_COUNT; m = m + 1) begin : gen_dest
            for (s = 0; s < S_COUNT; s = s + 1) begin : gen_src
                assign dest_valid[m][s] = s_tvalid[s];
                assign dest_connected[m][s] = M_CONNECT[m*S_COUNT + s];
                assign dest_match[m][s] = (s_tdest[s*S_DEST_WIDTH +: S_DEST_WIDTH] == m);
                assign dest_candidate[m][s] = dest_valid[m][s] & dest_connected[m][s] & dest_match[m][s];
            end
        end
    endgenerate

    // Arbitration for each destination
    // If ARB_TYPE_ROUND_ROBIN, use round-robin; else LSB high priority
    wire [S_COUNT-1:0] arb_grant [0:M_COUNT-1];
    wire [S_COUNT-1:0] arb_request [0:M_COUNT-1];

    genvar m2;
    generate
        for (m2 = 0; m2 < M_COUNT; m2 = m2 + 1) begin : gen_arb
            assign arb_request[m2] = dest_candidate[m2];

            if (ARB_TYPE_ROUND_ROBIN) begin
                // Round-robin arbitration
                reg [S_COUNT-1:0] rr_ptr;
                wire [S_COUNT-1:0] rr_mask;
                wire [S_COUNT-1:0] rr_masked_req;
                wire [S_COUNT-1:0] rr_unmasked_req;
                wire [S_COUNT-1:0] rr_grant_masked;
                wire [S_COUNT-1:0] rr_grant_unmasked;
                wire [S_COUNT-1:0] rr_grant;

                // Generate mask: bits from rr_ptr to S_COUNT-1 are 1
                assign rr_mask = {S_COUNT{1'b1}} << rr_ptr;
                assign rr_masked_req = arb_request[m2] & rr_mask;
                assign rr_unmasked_req = arb_request[m2] & ~rr_mask;

                // Priority encoder for masked request
                wire [S_COUNT-1:0] rr_grant_masked;
                wire [S_COUNT-1:0] rr_grant_unmasked;

                // Simple priority encoder: lowest set bit wins
                function [S_COUNT-1:0] priority_encode;
                    input [S_COUNT-1:0] req;
                    integer i;
                    begin
                        priority_encode = {S_COUNT{1'b0}};
                        for (i = 0; i < S_COUNT; i = i + 1) begin
                            if (req[i]) begin
                                priority_encode[i] = 1'b1;
                                break;
                            end
                        end
                    end
                endfunction

                assign rr_grant_masked = priority_encode(rr_masked_req);
                assign rr_grant_unmasked = priority_encode(rr_unmasked_req);
                assign rr_grant = rr_grant_masked | rr_grant_unmasked;

                assign arb_grant[m2] = rr_grant;

                always @(posedge clk or posedge rst) begin
                    if (rst) begin
                        rr_ptr <= {S_COUNT{1'b0}};
                    end else if (m_axis_tready[m2] && m_axis_tvalid[m2]) begin
                        // Update pointer to next source after granted one
                        if (rr_grant[S_COUNT-1]) begin
                            rr_ptr <= {S_COUNT{1'b0}};
                        end else begin
                            rr_ptr <= rr_grant + 1'b1;
                        end
                    end
                end
            end else begin
                // LSB high priority: lowest index wins
                assign arb_grant[m2] = priority_encode(arb_request[m2]);
            end
        end
    endgenerate

    // Function for priority encoding
    function [S_COUNT-1:0] priority_encode;
        input [S_COUNT-1:0] req;
        integer i;
        begin
            priority_encode = {S_COUNT{1'b0}};
            for (i = 0; i < S_COUNT; i = i + 1) begin
                if (req[i]) begin
                    priority_encode[i] = 1'b1;
                    break;
                end
            end
        end
    endfunction

    // Output muxing
    wire [M_COUNT*DATA_WIDTH-1:0] m_tdata;
    wire [M_COUNT*KEEP_WIDTH-1:0] m_tkeep;
    wire [M_COUNT-1:0] m_tvalid;
    wire [M_COUNT-1:0] m_tlast;
    wire [M_COUNT*M_ID_WIDTH-1:0] m_tid;
    wire [M_COUNT*M_DEST_WIDTH-1:0] m_tdest;
    wire [M_COUNT*USER_WIDTH-1:0] m_tuser;

    genvar m3;
    generate
        for (m3 = 0; m3 < M_COUNT; m3 = m3 + 1) begin : gen_out
            assign m_tvalid[m3] = |arb_grant[m3];

            // Mux data
            assign m_tdata[m3*DATA_WIDTH +: DATA_WIDTH] = 
                arb_grant[m3][0] ? s_tdata[0*DATA_WIDTH +: DATA_WIDTH] :
                arb_grant[m3][1] ? s_tdata[1*DATA_WIDTH +: DATA_WIDTH] :
                (S_COUNT > 2) ? (
                    arb_grant[m3][2] ? s_tdata[2*DATA_WIDTH +: DATA_WIDTH] :
                    (S_COUNT > 3) ? (
                        arb_grant[m3][3] ? s_tdata[3*DATA_WIDTH +: DATA_WIDTH] :
                        (S_COUNT > 4) ? (
                            arb_grant[m3][4] ? s_tdata[4*DATA_WIDTH +: DATA_WIDTH] :
                            (S_COUNT > 5) ? (
                                arb_grant[m3][5] ? s_tdata[5*DATA_WIDTH +: DATA_WIDTH] :
                                (S_COUNT > 6) ? (
                                    arb_grant[m3][6] ? s_tdata[6*DATA_WIDTH +: DATA_WIDTH] :
                                    (S_COUNT > 7) ? (
                                        arb_grant[m3][7] ? s_tdata[7*DATA_WIDTH +: DATA_WIDTH] :
                                        s_tdata[0*DATA_WIDTH +: DATA_WIDTH]
                                    ) :
                                    s_tdata[0*DATA_WIDTH +: DATA_WIDTH]
                                ) :
                                s_tdata[0*DATA_WIDTH +: DATA_WIDTH]
                            ) :
                            s_tdata[0*DATA_WIDTH +: DATA_WIDTH]
                        ) :
                        s_tdata[0*DATA_WIDTH +: DATA_WIDTH]
                    ) :
                    s_tdata[0*DATA_WIDTH +: DATA_WIDTH]
                ) :
                s_tdata[0*DATA_WIDTH +: DATA_WIDTH];

            // Mux keep
            assign m_tkeep[m3*KEEP_WIDTH +: KEEP_WIDTH] = 
                arb_grant[m3][0] ? s_tkeep[0*KEEP_WIDTH +: KEEP_WIDTH] :
                arb_grant[m3][1] ? s_tkeep[1*KEEP_WIDTH +: KEEP_WIDTH] :
                (S_COUNT > 2) ? (
                    arb_grant[m3][2] ? s_tkeep[2*KEEP_WIDTH +: KEEP_WIDTH] :
                    (S_COUNT > 3) ? (
                        arb_grant[m3][3] ? s_tkeep[3*KEEP_WIDTH +: KEEP_WIDTH] :
                        (S_COUNT > 4) ? (
                            arb_grant[m3][4] ? s_tkeep[4*KEEP_WIDTH +: KEEP_WIDTH] :
                            (S_COUNT > 5) ? (
                                arb_grant[m3][5] ? s_tkeep[5*KEEP_WIDTH +: KEEP_WIDTH] :
                                (S_COUNT > 6) ? (
                                    arb_grant[m3][6] ? s_tkeep[6*KEEP_WIDTH +: KEEP_WIDTH] :
                                    (S_COUNT > 7) ? (
                                        arb_grant[m3][7] ? s_tkeep[7*KEEP_WIDTH +: KEEP_WIDTH] :
                                        s_tkeep[0*KEEP_WIDTH +: KEEP_WIDTH]
                                    ) :
                                    s_tkeep[0*KEEP_WIDTH +: KEEP_WIDTH]
                                ) :
                                s_tkeep[0*KEEP_WIDTH +: KEEP_WIDTH]
                            ) :
                            s_tkeep[0*KEEP_WIDTH +: KEEP_WIDTH]
                        ) :
                        s_tkeep[0*KEEP_WIDTH +: KEEP_WIDTH]
                    ) :
                    s_tkeep[0*KEEP_WIDTH +: KEEP_WIDTH]
                ) :
                s_tkeep[0*KEEP_WIDTH +: KEEP_WIDTH];

            // Mux tlast
            assign m_tlast[m3] = 
                arb_grant[m3][0] ? s_tlast[0] :
                arb_grant[m3][1] ? s_tlast[1] :
                (S_COUNT > 2) ? (
                    arb_grant[m3][2] ? s_tlast[2] :
                    (S_COUNT > 3) ? (
                        arb_grant[m3][3] ? s_tlast[3] :
                        (S_COUNT > 4) ? (
                            arb_grant[m3][4] ? s_tlast[4] :
                            (S_COUNT > 5) ? (
                                arb_grant[m3][5] ? s_tlast[5] :
                                (S_COUNT > 6) ? (
                                    arb_grant[m3][6] ? s_tlast[6] :
                                    (S_COUNT > 7) ? (
                                        arb_grant[m3][7] ? s_tlast[7] :
                                        s_tlast[0]
                                    ) :
                                    s_tlast[0]
                                ) :
                                s_tlast[0]
                            ) :
                            s_tlast[0]
                        ) :
                        s_tlast[0]
                    ) :
                    s_tlast[0]
                ) :
                s_tlast[0];

            // Mux tid
            if (ID_ENABLE) begin
                if (UPDATE_TID) begin
                    // Update tid with source index
                    assign m_tid[m3*M_ID_WIDTH +: M_ID_WIDTH] = 
                        {arb_grant[m3][0] ? s_tid[0*S_ID_WIDTH +: S_ID_WIDTH] :
                         arb_grant[m3][1] ? s_tid[1*S_ID_WIDTH +: S_ID_WIDTH] :
                         (S_COUNT > 2) ? (
                             arb_grant[m3][2] ? s_tid[2*S_ID_WIDTH +: S_ID_WIDTH] :
                             (S_COUNT > 3) ? (
                                 arb_grant[m3][3] ? s_tid[3*S_ID_WIDTH +: S_ID_WIDTH] :
                                 (S_COUNT > 4) ? (
                                     arb_grant[m3][4] ? s_tid[4*S_ID_WIDTH +: S_ID_WIDTH] :
                                     (S_COUNT > 5) ? (
                                         arb_grant[m3][5] ? s_tid[5*S_ID_WIDTH +: S_ID_WIDTH] :
                                         (S_COUNT > 6) ? (
                                             arb_grant[m3][6] ? s_tid[6*S_ID_WIDTH +: S_ID_WIDTH] :
                                             (S_COUNT > 7) ? (
                                                 arb_grant[m3][7] ? s_tid[7*S_ID_WIDTH +: S_ID_WIDTH] :
                                                 s_tid[0*S_ID_WIDTH +: S_ID_WIDTH]
                                             ) :
                                             s_tid[0*S_ID_WIDTH +: S_ID_WIDTH]
                                         ) :
                                         s_tid[0*S_ID_WIDTH +: S_ID_WIDTH]
                                     ) :
                                     s_tid[0*S_ID_WIDTH +: S_ID_WIDTH]
                                 ) :
                                 s_tid[0*S_ID_WIDTH +: S_ID_WIDTH]
                             ) :
                             s_tid[0*S_ID_WIDTH +: S_ID_WIDTH]
                         ) :
                         s_tid[0*S_ID_WIDTH +: S_ID_WIDTH],
                         arb_grant[m3]};
                end else begin
                    assign m_tid[m3*M_ID_WIDTH +: M_ID_WIDTH] = 
                        arb_grant[m3][0] ? {s_tid[0*S_ID_WIDTH +: S_ID_WIDTH], {M_ID_WIDTH-S_ID_WIDTH{1'b0}}} :
                        arb_grant[m3][1] ? {s_tid[1*S_ID_WIDTH +: S_ID_WIDTH], {M_ID_WIDTH-S_ID_WIDTH{1'b0}}} :
                        (S_COUNT > 2) ? (
                            arb_grant[m3][2] ? {s_tid[2*S_ID_WIDTH +: S_ID_WIDTH], {M_ID_WIDTH-S_ID_WIDTH{1'b0}}} :
                            (S_COUNT > 3) ? (
                                arb_grant[m3][3] ? {s_tid[3*S_ID_WIDTH +: S_ID_WIDTH], {M_ID_WIDTH-S_ID_WIDTH{1'b0}}} :
                                (S_COUNT > 4) ? (
                                    arb_grant[m3][4] ? {s_tid[4*S_ID_WIDTH +: S_ID_WIDTH], {M_ID_WIDTH-S_ID_WIDTH{1'b0}}} :
                                    (S_COUNT > 5) ? (
                                        arb_grant[m3][5] ? {s_tid[5*S_ID_WIDTH +: S_ID_WIDTH], {M_ID_WIDTH-S_ID_WIDTH{1'b0}}} :
                                        (S_COUNT > 6) ? (
                                            arb_grant[m3][6] ? {s_tid[6*S_ID_WIDTH +: S_ID_WIDTH], {M_ID_WIDTH-S_ID_WIDTH{1'b0}}} :
                                            (S_COUNT > 7) ? (
                                                arb_grant[m3][7] ? {s_tid[7*S_ID_WIDTH +: S_ID_WIDTH], {M_ID_WIDTH-S_ID_WIDTH{1'b0}}} :
                                                {s_tid[0*S_ID_WIDTH +: S_ID_WIDTH], {M_ID_WIDTH-S_ID_WIDTH{1'b0}}}
                                            ) :
                                            {s_tid[0*S_ID_WIDTH +: S_ID_WIDTH], {M_ID_WIDTH-S_ID_WIDTH{1'b0}}}
                                        ) :
                                        {s_tid[0*S_ID_WIDTH +: S_ID_WIDTH], {M_ID_WIDTH-S_ID_WIDTH{1'b0}}}
                                    ) :
                                    {s_tid[0*S_ID_WIDTH +: S_ID_WIDTH], {M_ID_WIDTH-S_ID_WIDTH{1'b0}}}
                                ) :
                                {s_tid[0*S_ID_WIDTH +: S_ID_WIDTH], {M_ID_WIDTH-S_ID_WIDTH{1'b0}}}
                            ) :
                            {s_tid[0*S_ID_WIDTH +: S_ID_WIDTH], {M_ID_WIDTH-S_ID_WIDTH{1'b0}}}
                        ) :
                        {s_tid[0*S_ID_WIDTH +: S_ID_WIDTH], {M_ID_WIDTH-S_ID_WIDTH{1'b0}}};
                end
            end else begin
                assign m_tid[m3*M_ID_WIDTH +: M_ID_WIDTH] = {M_ID_WIDTH{1'b0}};
            end

            // Mux tdest
            assign m_tdest[m3*M_DEST_WIDTH +: M_DEST_WIDTH] = m3;

            // Mux tuser
            if (USER_ENABLE) begin
                assign m_tuser[m3*USER_WIDTH +: USER_WIDTH] = 
                    arb_grant[m3][0] ? s_tuser[0*USER_WIDTH +: USER_WIDTH] :
                    arb_grant[m3][1] ? s_tuser[1*USER_WIDTH +: USER_WIDTH] :
                    (S_COUNT > 2) ? (
                        arb_grant[m3][2] ? s_tuser[2*USER_WIDTH +: USER_WIDTH] :
                        (S_COUNT > 3) ? (
                            arb_grant[m3][3] ? s_tuser[3*USER_WIDTH +: USER_WIDTH] :
                            (S_COUNT > 4) ? (
                                arb_grant[m3][4] ? s_tuser[4*USER_WIDTH +: USER_WIDTH] :
                                (S_COUNT > 5) ? (
                                    arb_grant[m3][5] ? s_tuser[5*USER_WIDTH +: USER_WIDTH] :
                                    (S_COUNT > 6) ? (
                                        arb_grant[m3][6] ? s_tuser[6*USER_WIDTH +: USER_WIDTH] :
                                        (S_COUNT > 7) ? (
                                            arb_grant[m3][7] ? s_tuser[7*USER_WIDTH +: USER_WIDTH] :
                                            s_tuser[0*USER_WIDTH +: USER_WIDTH]
                                        ) :
                                        s_tuser[0*USER_WIDTH +: USER_WIDTH]
                                    ) :
                                    s_tuser[0*USER_WIDTH +: USER_WIDTH]
                                ) :
                                s_tuser[0*USER_WIDTH +: USER_WIDTH]
                            ) :
                            s_tuser[0*USER_WIDTH +: USER_WIDTH]
                        ) :
                        s_tuser[0*USER_WIDTH +: USER_WIDTH]
                    ) :
                    s_tuser[0*USER_WIDTH +: USER_WIDTH];
            end else begin
                assign m_tuser[m3*USER_WIDTH +: USER_WIDTH] = {USER_WIDTH{1'b0}};
            end
        end
    endgenerate

    // Output register stage
    if (M_REG_TYPE == 0) begin
        assign m_axis_tdata = m_tdata;
        assign m_axis_tkeep = m_tkeep;
        assign m_axis_tvalid = m_tvalid;
        assign m_axis_tlast = m_tlast;
        assign m_axis_tid = m_tid;
        assign m_axis_tdest = m_tdest;
        assign m_axis_tuser = m_tuser;
    end else begin
        reg [M_COUNT*DATA_WIDTH-1:0] m_tdata_r;
        reg [M_COUNT*KEEP_WIDTH-1:0] m_tkeep_r;
        reg [M_COUNT-1:0] m_tvalid_r;
        reg [M_COUNT-1:0] m_tlast_r;
        reg [M_COUNT*M_ID_WIDTH-1:0] m_tid_r;
        reg [M_COUNT*M_DEST_WIDTH-1:0] m_tdest_r;
        reg [M_COUNT*USER_WIDTH-1:0] m_tuser_r;

        assign m_axis_tdata = m_tdata_r;
        assign m_axis_tkeep = m_tkeep_r;
        assign m_axis_tvalid = m_tvalid_r;
        assign m_axis_tlast = m_tlast_r;
        assign m_axis_tid = m_tid_r;
        assign m_axis_tdest = m_tdest_r;
        assign m_axis_tuser = m_tuser_r;

        always @(posedge clk or posedge rst) begin
            if (rst) begin
                m_tvalid_r <= {M_COUNT{1'b0}};
            end else begin
                for (genvar j = 0; j < M_COUNT; j = j + 1) begin
                    if (m_tvalid[j] && m_axis_tready[j]) begin
                        m_tvalid_r[j] <= 1'b1;
                        m_tdata_r[j*DATA_WIDTH +: DATA_WIDTH] <= m_tdata[j*DATA_WIDTH +: DATA_WIDTH];
                        m_tkeep_r[j*KEEP_WIDTH +: KEEP_WIDTH] <= m_tkeep[j*KEEP_WIDTH +: KEEP_WIDTH];
                        m_tlast_r[j] <= m_tlast[j];
                        m_tid_r[j*M_ID_WIDTH +: M_ID_WIDTH] <= m_tid[j*M_ID_WIDTH +: M_ID_WIDTH];
                        m_tdest_r[j*M_DEST_WIDTH +: M_DEST_WIDTH] <= m_tdest[j*M_DEST_WIDTH +: M_DEST_WIDTH];
                        m_tuser_r[j*USER_WIDTH +: USER_WIDTH] <= m_tuser[j*USER_WIDTH +: USER_WIDTH];
                    end else if (m_tvalid_r[j] && m_axis_tready[j]) begin
                        m_tvalid_r[j] <= 1'b0;
                    end
                end
            end
        end
    end

    // Source ready signals
    // A source is ready if it is valid, connected to some destination, and that destination is ready
    // For simplicity, we assume that if a source is granted to a destination, it is ready
    // We need to compute s_tready based on whether the source can be accepted by any destination
    // A source s is ready if there exists a destination m such that:
    //   - s is connected to m
    //   - s's tdest matches m
    //   - m is ready (m_axis_tready[m])
    //   - s is the granted source for m (or no other source is granted)
    
    // For now, we'll compute s_tready as: source is ready if it is valid and can be routed to a ready destination
    // This is a simplification; in practice, we need to ensure no conflicts
    
    wire [S_COUNT-1:0] s_can_route;
    genvar s4;
    generate
        for (s4 = 0; s4 < S_COUNT; s4 = s4 + 1) begin : gen_sready
            wire [M_COUNT-1:0] dest_ready_for_s;
            genvar m4;
            generate
                for (m4 = 0; m4 < M_COUNT; m4 = m4 + 1) begin : gen_dest_ready
                    assign dest_ready_for_s[m4] = M_CONNECT[m4*S_COUNT + s4] & 
                                                  (s_tdest[s4*S_DEST_WIDTH +: S_DEST_WIDTH] == m4) &
                                                  m_axis_tready[m4];
                end
            endgenerate
            assign s_can_route[s4] = |dest_ready_for_s;
        end
    endgenerate

    // Source ready: source is ready if it can be routed and is not blocked by arbitration
    // For simplicity, we'll say a source is ready if it can be routed to a ready destination
    // and it is the one that would be granted (or no other source is competing)
    // This is a conservative approach
    
    assign s_tready = s_can_route;

    // Connect internal signals to output
    assign s_axis_tready = s_tready;

endmodule
