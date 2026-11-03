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

    /*
     * Internal signals
     */
    wire [S_COUNT-1:0]                      grant;
    wire [DATA_WIDTH-1:0]                   selected_data;
    wire [KEEP_WIDTH-1:0]                   selected_keep;
    wire                                    selected_last;
    wire [S_ID_WIDTH-1:0]                   selected_id;
    wire [S_DEST_WIDTH-1:0]                 selected_dest;
    wire [USER_WIDTH-1:0]                   selected_user;
    wire                                    valid_out;
    wire                                    ready_out;

    /*
     * Arbiter instance
     */
    arbiter #(
        .S_COUNT(S_COUNT),
        .ARB_TYPE_ROUND_ROBIN(ARB_TYPE_ROUND_ROBIN),
        .ARB_LSB_HIGH_PRIORITY(ARB_LSB_HIGH_PRIORITY)
    ) arbiter_inst (
        .clk(clk),
        .rst(rst),
        .s_axis_tvalid(s_axis_tvalid),
        .grant(grant)
    );

    /*
     * Muxes for selecting output data
     */
    generate
        genvar i;
        for (i = 0; i < S_COUNT; i = i + 1) begin : gen_muxes
            assign s_axis_tready[i] = grant[i] & ready_out;
        end
    endgenerate

    /*
     * Muxes for selecting output data
     */
    assign selected_data = grant[0] ? s_axis_tdata[DATA_WIDTH-1:0] :
                          grant[1] ? s_axis_tdata[2*DATA_WIDTH-1:DATA_WIDTH] :
                          grant[2] ? s_axis_tdata[3*DATA_WIDTH-1:2*DATA_WIDTH] :
                          grant[3] ? s_axis_tdata[4*DATA_WIDTH-1:3*DATA_WIDTH] :
                          {DATA_WIDTH{1'b0}};

    assign selected_keep = grant[0] ? s_axis_tkeep[KEEP_WIDTH-1:0] :
                          grant[1] ? s_axis_tkeep[2*KEEP_WIDTH-1:KEEP_WIDTH] :
                          grant[2] ? s_axis_tkeep[3*KEEP_WIDTH-1:2*KEEP_WIDTH] :
                          grant[3] ? s_axis_tkeep[4*KEEP_WIDTH-1:3*KEEP_WIDTH] :
                          {KEEP_WIDTH{1'b0}};

    assign selected_last = grant[0] ? s_axis_tlast[0] :
                          grant[1] ? s_axis_tlast[1] :
                          grant[2] ? s_axis_tlast[2] :
                          grant[3] ? s_axis_tlast[3] :
                          1'b0;

    assign selected_id = grant[0] ? s_axis_tid[S_ID_WIDTH-1:0] :
                        grant[1] ? s_axis_tid[2*S_ID_WIDTH-1:S_ID_WIDTH] :
                        grant[2] ? s_axis_tid[3*S_ID_WIDTH-1:2*S_ID_WIDTH] :
                        grant[3] ? s_axis_tid[4*S_ID_WIDTH-1:3*S_ID_WIDTH] :
                        {S_ID_WIDTH{1'b0}};

    assign selected_dest = grant[0] ? s_axis_tdest[S_DEST_WIDTH-1:0] :
                          grant[1] ? s_axis_tdest[2*S_DEST_WIDTH-1:S_DEST_WIDTH] :
                          grant[2] ? s_axis_tdest[3*S_DEST_WIDTH-1:2*S_DEST_WIDTH] :
                          grant[3] ? s_axis_tdest[4*S_DEST_WIDTH-1:3*S_DEST_WIDTH] :
                          {S_DEST_WIDTH{1'b0}};

    assign selected_user = grant[0] ? s_axis_tuser[USER_WIDTH-1:0] :
                          grant[1] ? s_axis_tuser[2*USER_WIDTH-1:USER_WIDTH] :
                          grant[2] ? s_axis_tuser[3*USER_WIDTH-1:2*USER_WIDTH] :
                          grant[3] ? s_axis_tuser[4*USER_WIDTH-1:3*USER_WIDTH] :
                          {USER_WIDTH{1'b0}};

    /*
     * Output assignments
     */
    assign valid_out = |grant & s_axis_tvalid;

    assign m_axis_tvalid[0] = valid_out & M_CONNECT[0][grant];
    assign m_axis_tvalid[1] = valid_out & M_CONNECT[1][grant];
    assign m_axis_tvalid[2] = valid_out & M_CONNECT[2][grant];
    assign m_axis_tvalid[3] = valid_out & M_CONNECT[3][grant];

    assign ready_out = |(m_axis_tready & m_axis_tvalid);

    assign m_axis_tdata[DATA_WIDTH-1:0] = selected_data;
    assign m_axis_tdata[2*DATA_WIDTH-1:DATA_WIDTH] = selected_data;
    assign m_axis_tdata[3*DATA_WIDTH-1:2*DATA_WIDTH] = selected_data;
    assign m_axis_tdata[4*DATA_WIDTH-1:3*DATA_WIDTH] = selected_data;

    assign m_axis_tkeep[KEEP_WIDTH-1:0] = selected_keep;
    assign m_axis_tkeep[2*KEEP_WIDTH-1:KEEP_WIDTH] = selected_keep;
    assign m_axis_tkeep[3*KEEP_WIDTH-1:2*KEEP_WIDTH] = selected_keep;
    assign m_axis_tkeep[4*KEEP_WIDTH-1:3*KEEP_WIDTH] = selected_keep;

    assign m_axis_tlast[0] = selected_last;
    assign m_axis_tlast[1] = selected_last;
    assign m_axis_tlast[2] = selected_last;
    assign m_axis_tlast[3] = selected_last;

    assign m_axis_tid[M_ID_WIDTH-1:0] = selected_id;
    assign m_axis_tid[2*M_ID_WIDTH-1:M_ID_WIDTH] = selected_id;
    assign m_axis_tid[3*M_ID_WIDTH-1:2*M_ID_WIDTH] = selected_id;
    assign m_axis_tid[4*M_ID_WIDTH-1:3*M_ID_WIDTH] = selected_id;

    assign m_axis_tdest[M_DEST_WIDTH-1:0] = selected_dest;
    assign m_axis_tdest[2*M_DEST_WIDTH-1:M_DEST_WIDTH] = selected_dest;
    assign m_axis_tdest[3*M_DEST_WIDTH-1:2*M_DEST_WIDTH] = selected_dest;
    assign m_axis_tdest[4*M_DEST_WIDTH-1:3*M_DEST_WIDTH] = selected_dest;

    assign m_axis_tuser[USER_WIDTH-1:0] = selected_user;
    assign m_axis_tuser[2*USER_WIDTH-1:USER_WIDTH] = selected_user;
    assign m_axis_tuser[3*USER_WIDTH-1:2*USER_WIDTH] = selected_user;
    assign m_axis_tuser[4*USER_WIDTH-1:3*USER_WIDTH] = selected_user;

endmodule

module arbiter #
(
    parameter S_COUNT = 4,
    parameter ARB_TYPE_ROUND_ROBIN = 1,
    parameter ARB_LSB_HIGH_PRIORITY = 1
)
(
    input  wire                             clk,
    input  wire                             rst,
    input  wire [S_COUNT-1:0]               s_axis_tvalid,
    output wire [S_COUNT-1:0]               grant
);

    /*
     * Internal signals
     */
    reg [S_COUNT-1:0]                       grant_reg;
    reg [S_COUNT-1:0]                       grant_next;
    reg [S_COUNT-1:0]                       request;

    /*
     * Request detection
     */
    assign request = s_axis_tvalid;

    /*
     * Round-robin arbitration logic
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant_reg <= {S_COUNT{1'b0}};
        end else begin
            grant_reg <= grant_next;
        end
    end

    always @(*) begin
        grant_next = grant_reg;
        if (|request) begin
            integer i;
            for (i = 0; i < S_COUNT; i = i + 1) begin
                if (request[i] && (grant_reg == {S_COUNT{1'b0}} || grant_reg[i] == 1'b1)) begin
                    grant_next = 1 << i;
                    break;
                end
            end
        end
    end

    /*
     * Grant output
     */
    assign grant = grant_reg;

endmodule
