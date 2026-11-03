module axis_register #
(
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter LAST_ENABLE = 1,
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1,
    parameter REG_TYPE = 2
)
(
    input  wire                   clk,
    input  wire                   rst,
    /*
     * AXI Stream input
     */
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    input  wire                   s_axis_tlast,
    input  wire [ID_WIDTH-1:0]    s_axis_tid,
    input  wire [DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [USER_WIDTH-1:0]  s_axis_tuser,
    /*
     * AXI Stream output
     */
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast,
    output wire [ID_WIDTH-1:0]    m_axis_tid,
    output wire [DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [USER_WIDTH-1:0]  m_axis_tuser
);

    // Internal signals
    reg                           s_axis_tready_int;
    reg                           m_axis_tvalid_int;
    reg [DATA_WIDTH-1:0]          tdata_reg;
    reg [KEEP_WIDTH-1:0]          tkeep_reg;
    reg                           tlast_reg;
    reg [ID_WIDTH-1:0]            tid_reg;
    reg [DEST_WIDTH-1:0]          tdest_reg;
    reg [USER_WIDTH-1:0]          tuser_reg;
    reg                           valid_reg;
    reg                           ready_reg;
    wire                          stall;

    // Stall condition for skid buffer
    assign stall = (REG_TYPE == 2) ? (m_axis_tvalid_int & ~m_axis_tready) : 0;

    // Assign output signals
    assign s_axis_tready = s_axis_tready_int;
    assign m_axis_tdata = tdata_reg;
    assign m_axis_tkeep = tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_int;
    assign m_axis_tlast = tlast_reg;
    assign m_axis_tid = tid_reg;
    assign m_axis_tdest = tdest_reg;
    assign m_axis_tuser = tuser_reg;

    // State transitions and handshakes
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tready_int <= 0;
            m_axis_tvalid_int <= 0;
            valid_reg <= 0;
            ready_reg <= 0;
        end else begin
            // Simple buffer or wire
            if (REG_TYPE == 0) begin
                s_axis_tready_int <= m_axis_tready;
                m_axis_tvalid_int <= s_axis_tvalid;
                if (s_axis_tvalid & m_axis_tready) begin
                    tdata_reg <= s_axis_tdata;
                    if (KEEP_ENABLE) tkeep_reg <= s_axis_tkeep;
                    if (LAST_ENABLE) tlast_reg <= s_axis_tlast;
                    if (ID_ENABLE) tid_reg <= s_axis_tid;
                    if (DEST_ENABLE) tdest_reg <= s_axis_tdest;
                    if (USER_ENABLE) tuser_reg <= s_axis_tuser;
                end
            end else if (REG_TYPE == 1) begin
                s_axis_tready_int <= ~valid_reg;
                m_axis_tvalid_int <= valid_reg;
                if (s_axis_tvalid & s_axis_tready_int) begin
                    tdata_reg <= s_axis_tdata;
                    if (KEEP_ENABLE) tkeep_reg <= s_axis_tkeep;
                    if (LAST_ENABLE) tlast_reg <= s_axis_tlast;
                    if (ID_ENABLE) tid_reg <= s_axis_tid;
                    if (DEST_ENABLE) tdest_reg <= s_axis_tdest;
                    if (USER_ENABLE) tuser_reg <= s_axis_tuser;
                    valid_reg <= 1;
                end else if (m_axis_tvalid_int & m_axis_tready) begin
                    valid_reg <= 0;
                end
            end else if (REG_TYPE == 2) begin
                s_axis_tready_int <= ~valid_reg | ~stall;
                m_axis_tvalid_int <= valid_reg | stall;
                if (s_axis_tvalid & s_axis_tready_int & ~stall) begin
                    tdata_reg <= s_axis_tdata;
                    if (KEEP_ENABLE) tkeep_reg <= s_axis_tkeep;
                    if (LAST_ENABLE) tlast_reg <= s_axis_tlast;
                    if (ID_ENABLE) tid_reg <= s_axis_tid;
                    if (DEST_ENABLE) tdest_reg <= s_axis_tdest;
                    if (USER_ENABLE) tuser_reg <= s_axis_tuser;
                    valid_reg <= 1;
                end else if (m_axis_tvalid_int & m_axis_tready) begin
                    valid_reg <= 0;
                end
            end
        end
    end

endmodule
