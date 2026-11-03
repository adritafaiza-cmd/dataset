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

    wire [S_COUNT-1:0] grant;
    wire [DATA_WIDTH-1:0] selected_data;
    wire [KEEP_WIDTH-1:0] selected_keep;
    wire selected_last;
    wire [S_ID_WIDTH-1:0] selected_id;
    wire [S_DEST_WIDTH-1:0] selected_dest;
    wire [USER_WIDTH-1:0] selected_user;

    integer i, j;

    // Arbiter instance
    arbiter #(
        .S_COUNT(S_COUNT)
    ) arbiter_inst (
        .clk(clk),
        .rst(rst),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .grant(grant)
    );

    // Muxes for selecting the correct input based on the grant signal
    always @(*) begin
        selected_data = {DATA_WIDTH{1'b0}};
        selected_keep = {KEEP_WIDTH{1'b0}};
        selected_last = 1'b0;
        selected_id = {S_ID_WIDTH{1'b0}};
        selected_dest = {S_DEST_WIDTH{1'b0}};
        selected_user = {USER_WIDTH{1'b0}};

        for (i = 0; i < S_COUNT; i = i + 1) begin
            if (grant[i]) begin
                selected_data = s_axis_tdata[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH];
                selected_keep = s_axis_tkeep[(i+1)*KEEP_WIDTH-1:i*KEEP_WIDTH];
                selected_last = s_axis_tlast[i];
                selected_id = s_axis_tid[(i+1)*S_ID_WIDTH-1:i*S_ID_WIDTH];
                selected_dest = s_axis_tdest[(i+1)*S_DEST_WIDTH-1:i*S_DEST_WIDTH];
                selected_user = s_axis_tuser[(i+1)*USER_WIDTH-1:i*USER_WIDTH];
            end
        end
    end

    // Routing the selected signals to the appropriate output
    always @(*) begin
        m_axis_tdata = {M_COUNT*DATA_WIDTH{1'b0}};
        m_axis_tkeep = {M_COUNT*KEEP_WIDTH{1'b0}};
        m_axis_tvalid = {M_COUNT{1'b0}};
        m_axis_tlast = {M_COUNT{1'b0}};
        m_axis_tid = {M_COUNT*M_ID_WIDTH{1'b0}};
        m_axis_tdest = {M_COUNT*M_DEST_WIDTH{1'b0}};
        m_axis_tuser = {M_COUNT*USER_WIDTH{1'b0}};

        for (i = 0; i < S_COUNT; i = i + 1) begin
            for (j = 0; j < M_COUNT; j = j + 1) begin
                if (grant[i] && M_CONNECT[j][i]) begin
                    m_axis_tdata[(j+1)*DATA_WIDTH-1:j*DATA_WIDTH] = selected_data;
                    m_axis_tkeep[(j+1)*KEEP_WIDTH-1:j*KEEP_WIDTH] = selected_keep;
                    m_axis_tvalid[j] = s_axis_tvalid[i];
                    m_axis_tlast[j] = selected_last;
                    m_axis_tid[(j+1)*M_ID_WIDTH-1:j*M_ID_WIDTH] = selected_id;
                    m_axis_tdest[(j+1)*M_DEST_WIDTH-1:j*M_DEST_WIDTH] = selected_dest;
                    m_axis_tuser[(j+1)*USER_WIDTH-1:j*USER_WIDTH] = selected_user;
                end
            end
        end
    end

endmodule

module arbiter #
(
    parameter S_COUNT = 4
)
(
    input  wire                 clk,
    input  wire                 rst,
    input  wire [S_COUNT-1:0]   s_axis_tvalid,
    output wire [S_COUNT-1:0]   s_axis_tready,
    output wire [S_COUNT-1:0]   grant
);

    reg [$clog2(S_COUNT)-1:0] round_robin_ptr;
    reg [S_COUNT-1:0]         request;

    always @(*) begin
        request = s_axis_tvalid;
        for (integer i = 0; i < S_COUNT; i = i + 1) begin
            if (grant[i]) begin
                request[i] = 1'b0;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            round_robin_ptr <= 0;
            grant <= 0;
        end else begin
            if (|request) begin
                for (integer i = 0; i < S_COUNT; i = i + 1) begin
                    integer idx = (round_robin_ptr + i) % S_COUNT;
                    if (request[idx]) begin
                        grant <= {S_COUNT{1'b0}};
                        grant[idx] <= 1'b1;
                        round_robin_ptr <= idx + 1;
                        break;
                    end
                end
            end else begin
                grant <= 0;
            end
        end
    end

    assign s_axis_tready = grant;

endmodule
