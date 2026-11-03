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
    reg  [DATA_WIDTH-1:0]  reg_tdata;
    reg  [KEEP_WIDTH-1:0]  reg_tkeep;
    reg                    reg_tvalid;
    reg                    reg_tlast;
    reg  [ID_WIDTH-1:0]    reg_tid;
    reg  [DEST_WIDTH-1:0]  reg_tdest;
    reg  [USER_WIDTH-1:0]  reg_tuser;
    reg                    reg_tready;
    reg  [DATA_WIDTH-1:0]  next_tdata;
    reg  [KEEP_WIDTH-1:0]  next_tkeep;
    reg                    next_tvalid;
    reg                    next_tlast;
    reg  [ID_WIDTH-1:0]    next_tid;
    reg  [DEST_WIDTH-1:0]  next_tdest;
    reg  [USER_WIDTH-1:0]  next_tuser;
    reg                    next_tready;
    reg                    skid_buffer_full;

    // Wire type
    wire [DATA_WIDTH-1:0]  wire_tdata;
    wire [KEEP_WIDTH-1:0]  wire_tkeep;
    wire                   wire_tvalid;
    wire                   wire_tlast;
    wire [ID_WIDTH-1:0]    wire_tid;
    wire [DEST_WIDTH-1:0]  wire_tdest;
    wire [USER_WIDTH-1:0]  wire_tuser;

    // Simple buffer type
    reg  [DATA_WIDTH-1:0]  buffer_tdata;
    reg  [KEEP_WIDTH-1:0]  buffer_tkeep;
    reg                    buffer_tvalid;
    reg                    buffer_tlast;
    reg  [ID_WIDTH-1:0]    buffer_tid;
    reg  [DEST_WIDTH-1:0]  buffer_tdest;
    reg  [USER_WIDTH-1:0]  buffer_tuser;

    // Skid buffer type
    reg  [DATA_WIDTH-1:0]  skid_tdata;
    reg  [KEEP_WIDTH-1:0]  skid_tkeep;
    reg                    skid_tvalid;
    reg                    skid_tlast;
    reg  [ID_WIDTH-1:0]    skid_tid;
    reg  [DEST_WIDTH-1:0]  skid_tdest;
    reg  [USER_WIDTH-1:0]  skid_tuser;

    // Output assignments
    assign m_axis_tdata = (REG_TYPE == 0) ? wire_tdata : (REG_TYPE == 1) ? buffer_tdata : skid_tdata;
    assign m_axis_tkeep = (REG_TYPE == 0) ? wire_tkeep : (REG_TYPE == 1) ? buffer_tkeep : skid_tkeep;
    assign m_axis_tvalid = (REG_TYPE == 0) ? wire_tvalid : (REG_TYPE == 1) ? buffer_tvalid : skid_tvalid;
    assign m_axis_tlast = (REG_TYPE == 0) ? wire_tlast : (REG_TYPE == 1) ? buffer_tlast : skid_tlast;
    assign m_axis_tid = (REG_TYPE == 0) ? wire_tid : (REG_TYPE == 1) ? buffer_tid : skid_tid;
    assign m_axis_tdest = (REG_TYPE == 0) ? wire_tdest : (REG_TYPE == 1) ? buffer_tdest : skid_tdest;
    assign m_axis_tuser = (REG_TYPE == 0) ? wire_tuser : (REG_TYPE == 1) ? buffer_tuser : skid_tuser;

    // Wire type assignments
    assign wire_tdata = s_axis_tdata;
    assign wire_tkeep = s_axis_tkeep;
    assign wire_tvalid = s_axis_tvalid;
    assign wire_tlast = s_axis_tlast;
    assign wire_tid = s_axis_tid;
    assign wire_tdest = s_axis_tdest;
    assign wire_tuser = s_axis_tuser;

    // Simple buffer type assignments
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buffer_tdata <= 0;
            buffer_tkeep <= 0;
            buffer_tvalid <= 0;
            buffer_tlast <= 0;
            buffer_tid <= 0;
            buffer_tdest <= 0;
            buffer_tuser <= 0;
        end else if (s_axis_tvalid && m_axis_tready) begin
            buffer_tdata <= s_axis_tdata;
            buffer_tkeep <= s_axis_tkeep;
            buffer_tvalid <= s_axis_tvalid;
            buffer_tlast <= s_axis_tlast;
            buffer_tid <= s_axis_tid;
            buffer_tdest <= s_axis_tdest;
            buffer_tuser <= s_axis_tuser;
        end
    end

    // Skid buffer type assignments
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            skid_tdata <= 0;
            skid_tkeep <= 0;
            skid_tvalid <= 0;
            skid_tlast <= 0;
            skid_tid <= 0;
            skid_tdest <= 0;
            skid_tuser <= 0;
            skid_buffer_full <= 0;
        end else begin
            if (s_axis_tvalid && !m_axis_tready && !skid_buffer_full) begin
                skid_tdata <= s_axis_tdata;
                skid_tkeep <= s_axis_tkeep;
                skid_tvalid <= s_axis_tvalid;
                skid_tlast <= s_axis_tlast;
                skid_tid <= s_axis_tid;
                skid_tdest <= s_axis_tdest;
                skid_tuser <= s_axis_tuser;
                skid_buffer_full <= 1;
            end else if (m_axis_tready && skid_buffer_full) begin
                skid_buffer_full <= 0;
            end
        end
    end

    // Output ready signal
    always @(*) begin
        case (REG_TYPE)
            0: s_axis_tready = m_axis_tready;
            1: s_axis_tready = m_axis_tready;
            2: s_axis_tready = m_axis_tready || !skid_buffer_full;
            default: s_axis_tready = 0;
        endcase
    end

endmodule
