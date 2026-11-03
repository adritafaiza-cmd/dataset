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
    reg [S_COUNT-1:0]                       s_axis_tready_reg;
    reg [M_COUNT-1:0]                       m_axis_tvalid_reg;
    reg [M_COUNT-1:0]                       m_axis_tready_reg;
    reg [S_COUNT*M_COUNT-1:0]               request;
    reg [S_COUNT*M_COUNT-1:0]               grant;
    reg [M_COUNT-1:0]                       grant_next;
    reg [M_COUNT-1:0]                       grant_reg;

    // Instantiate round-robin arbiter for each output
    genvar i;
    generate
        for (i = 0; i < M_COUNT; i = i + 1) begin : arbiter_gen
            axis_round_robin_arbiter #(
                .S_COUNT(S_COUNT),
                .LSB_HIGH_PRIORITY(ARB_LSB_HIGH_PRIORITY)
            ) arbiter_inst (
                .clk(clk),
                .rst(rst),
                .request(request[i*S_COUNT+:S_COUNT]),
                .grant(grant[i*S_COUNT+:S_COUNT])
            );
        end
    endgenerate

    // Routing logic
    always @(*) begin
        s_axis_tready_reg = '0;
        m_axis_tvalid_reg = '0;
        m_axis_tdata = '0;
        m_axis_tkeep = '0;
        m_axis_tlast = '0;
        m_axis_tid = '0;
        m_axis_tdest = '0;
        m_axis_tuser = '0;

        request = '0;
        grant_next = grant_reg;

        for (integer j = 0; j < M_COUNT; j = j + 1) begin
            for (integer k = 0; k < S_COUNT; k = k + 1) begin
                if (s_axis_tvalid[k] && (s_axis_tdest[k*S_DEST_WIDTH+:S_DEST_WIDTH] == j)) begin
                    request[j*S_COUNT + k] = 1'b1;
                end
            end
        end

        for (integer l = 0; l < M_COUNT; l = l + 1) begin
            for (integer m = 0; m < S_COUNT; m = m + 1) begin
                if (grant[l*S_COUNT + m]) begin
                    s_axis_tready_reg[m] = m_axis_tready[l];
                    m_axis_tvalid_reg[l] = s_axis_tvalid[m];
                    m_axis_tdata[l*DATA_WIDTH+:DATA_WIDTH] = s_axis_tdata[m*DATA_WIDTH+:DATA_WIDTH];
                    m_axis_tkeep[l*KEEP_WIDTH+:KEEP_WIDTH] = s_axis_tkeep[m*KEEP_WIDTH+:KEEP_WIDTH];
                    m_axis_tlast[l] = s_axis_tlast[m];
                    m_axis_tid[l*M_ID_WIDTH+:M_ID_WIDTH] = s_axis_tid[m*S_ID_WIDTH+:S_ID_WIDTH];
                    m_axis_tdest[l*M_DEST_WIDTH+:M_DEST_WIDTH] = s_axis_tdest[m*S_DEST_WIDTH+:S_DEST_WIDTH];
                    m_axis_tuser[l*USER_WIDTH+:USER_WIDTH] = s_axis_tuser[m*USER_WIDTH+:USER_WIDTH];
                end
            end
            if (grant_next[l] != grant_reg[l]) begin
                grant_next[l] = grant_reg[l];
            end
        end
    end

    // Grant register update
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant_reg <= '0;
        end else begin
            grant_reg <= grant_next;
        end
    end

    // Output assignments
    assign s_axis_tready = s_axis_tready_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;

endmodule

module axis_round_robin_arbiter #
(
    parameter S_COUNT = 4,
    parameter LSB_HIGH_PRIORITY = 1
)
(
    input  wire                     clk,
    input  wire                     rst,
    input  wire [S_COUNT-1:0]       request,
    output wire [S_COUNT-1:0]       grant
);

    reg [S_COUNT-1:0]               grant_reg;
    reg [$clog2(S_COUNT)-1:0]       grant_ptr;

    // Grant logic
    always @(*) begin
        grant = '0;
        if (request[grant_ptr]) begin
            grant[grant_ptr] = 1'b1;
        end else begin
            for (integer i = 0; i < S_COUNT; i = i + 1) begin
                if (request[i]) begin
                    grant[i] = 1'b1;
                    break;
                end
            end
        end
    end

    // Pointer update logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant_ptr <= 0;
        end else if (|request) begin
            grant_ptr <= grant_ptr + 1;
        end
    end

endmodule
