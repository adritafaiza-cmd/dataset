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

    reg [DATA_WIDTH-1:0]          reg_tdata;
    reg [KEEP_WIDTH-1:0]          reg_tkeep;
    reg                           reg_tvalid;
    reg                           reg_tlast;
    reg [ID_WIDTH-1:0]            reg_tid;
    reg [DEST_WIDTH-1:0]          reg_tdest;
    reg [USER_WIDTH-1:0]          reg_tuser;

    wire                          next_reg_tvalid;
    wire                          next_reg_tready;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_tvalid <= 0;
        end else begin
            reg_tvalid <= next_reg_tvalid;
        end
    end

    always @(*) begin
        next_reg_tvalid = reg_tvalid;

        case (REG_TYPE)
            0: begin // Wire
                m_axis_tdata = s_axis_tdata;
                m_axis_tkeep = s_axis_tkeep;
                m_axis_tvalid = s_axis_tvalid;
                m_axis_tlast = s_axis_tlast;
                m_axis_tid = s_axis_tid;
                m_axis_tdest = s_axis_tdest;
                m_axis_tuser = s_axis_tuser;
                s_axis_tready = m_axis_tready;
                next_reg_tvalid = 0;
            end
            1: begin // Buffer
                m_axis_tdata = reg_tdata;
                m_axis_tkeep = reg_tkeep;
                m_axis_tvalid = reg_tvalid;
                m_axis_tlast = reg_tlast;
                m_axis_tid = reg_tid;
                m_axis_tdest = reg_tdest;
                m_axis_tuser = reg_tuser;
                s_axis_tready = m_axis_tready;
                if (s_axis_tvalid && m_axis_tready) begin
                    next_reg_tvalid = s_axis_tvalid;
                    reg_tdata = s_axis_tdata;
                    reg_tkeep = s_axis_tkeep;
                    reg_tlast = s_axis_tlast;
                    reg_tid = s_axis_tid;
                    reg_tdest = s_axis_tdest;
                    reg_tuser = s_axis_tuser;
                end
            end
            2: begin // Skid Buffer
                m_axis_tdata = reg_tvalid ? reg_tdata : s_axis_tdata;
                m_axis_tkeep = reg_tvalid ? reg_tkeep : s_axis_tkeep;
                m_axis_tvalid = reg_tvalid || s_axis_tvalid;
                m_axis_tlast = reg_tvalid ? reg_tlast : s_axis_tlast;
                m_axis_tid = reg_tvalid ? reg_tid : s_axis_tid;
                m_axis_tdest = reg_tvalid ? reg_tdest : s_axis_tdest;
                m_axis_tuser = reg_tvalid ? reg_tuser : s_axis_tuser;
                s_axis_tready = ~reg_tvalid || m_axis_tready;
                if (s_axis_tvalid && ~m_axis_tready) begin
                    next_reg_tvalid = 1;
                    reg_tdata = s_axis_tdata;
                    reg_tkeep = s_axis_tkeep;
                    reg_tlast = s_axis_tlast;
                    reg_tid = s_axis_tid;
                    reg_tdest = s_axis_tdest;
                    reg_tuser = s_axis_tuser;
                end else if (m_axis_tready) begin
                    next_reg_tvalid = 0;
                end
            end
            default: begin
                m_axis_tdata = reg_tdata;
                m_axis_tkeep = reg_tkeep;
                m_axis_tvalid = reg_tvalid;
                m_axis_tlast = reg_tlast;
                m_axis_tid = reg_tid;
                m_axis_tdest = reg_tdest;
                m_axis_tuser = reg_tuser;
                s_axis_tready = m_axis_tready;
            end
        endcase
    end

endmodule
