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
    reg [S_COUNT-1:0] [DATA_WIDTH-1:0]     s_axis_tdata_reg;
    reg [S_COUNT-1:0] [KEEP_WIDTH-1:0]     s_axis_tkeep_reg;
    reg [S_COUNT-1:0]                      s_axis_tvalid_reg;
    reg [S_COUNT-1:0]                      s_axis_tready_reg;
    reg [S_COUNT-1:0]                      s_axis_tlast_reg;
    reg [S_COUNT-1:0] [S_ID_WIDTH-1:0]     s_axis_tid_reg;
    reg [S_COUNT-1:0] [S_DEST_WIDTH-1:0]   s_axis_tdest_reg;
    reg [S_COUNT-1:0] [USER_WIDTH-1:0]     s_axis_tuser_reg;

    reg [M_COUNT-1:0] [DATA_WIDTH-1:0]     m_axis_tdata_reg;
    reg [M_COUNT-1:0] [KEEP_WIDTH-1:0]     m_axis_tkeep_reg;
    reg [M_COUNT-1:0]                      m_axis_tvalid_reg;
    reg [M_COUNT-1:0]                      m_axis_tlast_reg;
    reg [M_COUNT-1:0] [M_ID_WIDTH-1:0]     m_axis_tid_reg;
    reg [M_COUNT-1:0] [M_DEST_WIDTH-1:0]   m_axis_tdest_reg;
    reg [M_COUNT-1:0] [USER_WIDTH-1:0]     m_axis_tuser_reg;

    reg [S_COUNT-1:0]                      grant;
    reg [S_COUNT-1:0]                      request;
    reg [S_COUNT-1:0]                      request_reg;

    // Register inputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tdata_reg <= {S_COUNT{DATA_WIDTH{1'b0}}};
            s_axis_tkeep_reg <= {S_COUNT{KEEP_WIDTH{1'b0}}};
            s_axis_tvalid_reg <= {S_COUNT{1'b0}};
            s_axis_tlast_reg <= {S_COUNT{1'b0}};
            s_axis_tid_reg <= {S_COUNT{S_ID_WIDTH{1'b0}}};
            s_axis_tdest_reg <= {S_COUNT{S_DEST_WIDTH{1'b0}}};
            s_axis_tuser_reg <= {S_COUNT{USER_WIDTH{1'b0}}};
        end else begin
            if (S_REG_TYPE == 1) begin
                s_axis_tdata_reg <= s_axis_tdata;
                s_axis_tkeep_reg <= s_axis_tkeep;
                s_axis_tvalid_reg <= s_axis_tvalid;
                s_axis_tlast_reg <= s_axis_tlast;
                s_axis_tid_reg <= s_axis_tid;
                s_axis_tdest_reg <= s_axis_tdest;
                s_axis_tuser_reg <= s_axis_tuser;
            end else if (S_REG_TYPE == 2) begin
                if (!s_axis_tready_reg) begin
                    s_axis_tdata_reg <= s_axis_tdata;
                    s_axis_tkeep_reg <= s_axis_tkeep;
                    s_axis_tvalid_reg <= s_axis_tvalid;
                    s_axis_tlast_reg <= s_axis_tlast;
                    s_axis_tid_reg <= s_axis_tid;
                    s_axis_tdest_reg <= s_axis_tdest;
                    s_axis_tuser_reg <= s_axis_tuser;
                end
            end
        end
    end

    // Register outputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_tdata_reg <= {M_COUNT{DATA_WIDTH{1'b0}}};
            m_axis_tkeep_reg <= {M_COUNT{KEEP_WIDTH{1'b0}}};
            m_axis_tvalid_reg <= {M_COUNT{1'b0}};
            m_axis_tlast_reg <= {M_COUNT{1'b0}};
            m_axis_tid_reg <= {M_COUNT{M_ID_WIDTH{1'b0}}};
            m_axis_tdest_reg <= {M_COUNT{M_DEST_WIDTH{1'b0}}};
            m_axis_tuser_reg <= {M_COUNT{USER_WIDTH{1'b0}}};
        end else begin
            if (M_REG_TYPE == 1) begin
                m_axis_tdata_reg <= m_axis_tdata;
                m_axis_tkeep_reg <= m_axis_tkeep;
                m_axis_tvalid_reg <= m_axis_tvalid;
                m_axis_tlast_reg <= m_axis_tlast;
                m_axis_tid_reg <= m_axis_tid;
                m_axis_tdest_reg <= m_axis_tdest;
                m_axis_tuser_reg <= m_axis_tuser;
            end else if (M_REG_TYPE == 2) begin
                if (!m_axis_tready) begin
                    m_axis_tdata_reg <= m_axis_tdata;
                    m_axis_tkeep_reg <= m_axis_tkeep;
                    m_axis_tvalid_reg <= m_axis_tvalid;
                    m_axis_tlast_reg <= m_axis_tlast;
                    m_axis_tid_reg <= m_axis_tid;
                    m_axis_tdest_reg <= m_axis_tdest;
                    m_axis_tuser_reg <= m_axis_tuser;
                end
            end
        end
    end

    // Generate requests
    always @(*) begin
        request = s_axis_tvalid_reg;
    end

    // Round-robin arbiter
    generate
        if (ARB_TYPE_ROUND_ROBIN) begin
            rr_arbiter #(
                .WIDTH(S_COUNT)
            ) rr_arbiter_inst (
                .clk(clk),
                .rst(rst),
                .request(request),
                .grant(grant)
            );
        end else begin
            // Priority arbiter or other types can be added here
            assign grant = request;
        end
    endgenerate

    // Register requests
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            request_reg <= {S_COUNT{1'b0}};
        end else begin
            request_reg <= request;
        end
    end

    // Route data based on tdest
    always @(*) begin
        m_axis_tdata = {M_COUNT{DATA_WIDTH{1'b0}}};
        m_axis_tkeep = {M_COUNT{KEEP_WIDTH{1'b0}}};
        m_axis_tvalid = {M_COUNT{1'b0}};
        m_axis_tlast = {M_COUNT{1'b0}};
        m_axis_tid = {M_COUNT{M_ID_WIDTH{1'b0}}};
        m_axis_tdest = {M_COUNT{M_DEST_WIDTH{1'b0}}};
        m_axis_tuser = {M_COUNT{USER_WIDTH{1'b0}}};

        s_axis_tready_reg = {S_COUNT{1'b0}};

        for (int i = 0; i < S_COUNT; i = i + 1) begin
            if (grant[i] && request_reg[i]) begin
                int dest = s_axis_tdest_reg[i][M_DEST_WIDTH-1:0];
                if (dest < M_COUNT) begin
                    m_axis_tdata[dest*DATA_WIDTH +: DATA_WIDTH] = s_axis_tdata_reg[i];
                    m_axis_tkeep[dest*KEEP_WIDTH +: KEEP_WIDTH] = s_axis_tkeep_reg[i];
                    m_axis_tvalid[dest] = 1'b1;
                    m_axis_tlast[dest] = s_axis_tlast_reg[i];
                    m_axis_tid[dest*M_ID_WIDTH +: M_ID_WIDTH] = s_axis_tid_reg[i];
                    m_axis_tdest[dest*M_DEST_WIDTH +: M_DEST_WIDTH] = s_axis_tdest_reg[i][M_DEST_WIDTH-1:0];
                    m_axis_tuser[dest*USER_WIDTH +: USER_WIDTH] = s_axis_tuser_reg[i];
                    s_axis_tready_reg[i] = m_axis_tready[dest];
                end
            end
        end
    end

    // Output assignments
    assign s_axis_tready = s_axis_tready_reg;
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

endmodule

// Round-robin arbiter module
module rr_arbiter #
(
    parameter WIDTH = 4
)
(
    input  wire clk,
    input  wire rst,
    input  wire [WIDTH-1:0] request,
    output reg  [WIDTH-1:0] grant
);

    reg [$clog2(WIDTH)-1:0] pointer;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant <= {WIDTH{1'b0}};
            pointer <= 0;
        end else begin
            grant <= {WIDTH{1'b0}};
            if (|request) begin
                for (int i = 0; i < WIDTH; i = i + 1) begin
                    int idx = (pointer + i) % WIDTH;
                    if (request[idx]) begin
                        grant[idx] <= 1'b1;
                        pointer <= idx + 1;
                        break;
                    end
                end
            end
        end
    end

endmodule
