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

    reg [DATA_WIDTH-1:0]  reg_tdata;
    reg [KEEP_WIDTH-1:0]  reg_tkeep;
    reg                   reg_tvalid;
    reg                   reg_tlast;
    reg [ID_WIDTH-1:0]    reg_tid;
    reg [DEST_WIDTH-1:0]  reg_tdest;
    reg [USER_WIDTH-1:0]  reg_tuser;

    reg [DATA_WIDTH-1:0]  skid_tdata;
    reg [KEEP_WIDTH-1:0]  skid_tkeep;
    reg                   skid_tvalid;
    reg                   skid_tlast;
    reg [ID_WIDTH-1:0]    skid_tid;
    reg [DEST_WIDTH-1:0]  skid_tdest;
    reg [USER_WIDTH-1:0]  skid_tuser;

    wire                  s_axis_tready_wire;
    wire                  s_axis_tready_buffer;
    wire                  s_axis_tready_skid;

    assign s_axis_tready_wire = m_axis_tready;
    assign s_axis_tready_buffer = ~reg_tvalid | m_axis_tready;
    assign s_axis_tready_skid = ~skid_tvalid | m_axis_tready;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_tdata <= 0;
            reg_tkeep <= 0;
            reg_tvalid <= 0;
            reg_tlast <= 0;
            reg_tid <= 0;
            reg_tdest <= 0;
            reg_tuser <= 0;

            skid_tdata <= 0;
            skid_tkeep <= 0;
            skid_tvalid <= 0;
            skid_tlast <= 0;
            skid_tid <= 0;
            skid_tdest <= 0;
            skid_tuser <= 0;
        end else begin
            case (REG_TYPE)
                0: begin
                    // Wire
                    reg_tdata <= s_axis_tdata;
                    reg_tkeep <= s_axis_tkeep;
                    reg_tvalid <= s_axis_tvalid;
                    reg_tlast <= s_axis_tlast;
                    reg_tid <= s_axis_tid;
                    reg_tdest <= s_axis_tdest;
                    reg_tuser <= s_axis_tuser;
                end
                1: begin
                    // Simple buffer
                    if (m_axis_tready) begin
                        reg_tdata <= s_axis_tdata;
                        reg_tkeep <= s_axis_tkeep;
                        reg_tvalid <= s_axis_tvalid;
                        reg_tlast <= s_axis_tlast;
                        reg_tid <= s_axis_tid;
                        reg_tdest <= s_axis_tdest;
                        reg_tuser <= s_axis_tuser;
                    end
                end
                2: begin
                    // Skid buffer
                    if (m_axis_tready) begin
                        if (skid_tvalid) begin
                            reg_tdata <= skid_tdata;
                            reg_tkeep <= skid_tkeep;
                            reg_tvalid <= skid_tvalid;
                            reg_tlast <= skid_tlast;
                            reg_tid <= skid_tid;
                            reg_tdest <= skid_tdest;
                            reg_tuser <= skid_tuser;
                            skid_tvalid <= 0;
                        end else begin
                            reg_tdata <= s_axis_tdata;
                            reg_tkeep <= s_axis_tkeep;
                            reg_tvalid <= s_axis_tvalid;
                            reg_tlast <= s_axis_tlast;
                            reg_tid <= s_axis_tid;
                            reg_tdest <= s_axis_tdest;
                            reg_tuser <= s_axis_tuser;
                        end
                    end else begin
                        if (s_axis_tvalid && !reg_tvalid) begin
                            skid_tdata <= s_axis_tdata;
                            skid_tkeep <= s_axis_tkeep;
                            skid_tvalid <= s_axis_tvalid;
                            skid_tlast <= s_axis_tlast;
                            skid_tid <= s_axis_tid;
                            skid_tdest <= s_axis_tdest;
                            skid_tuser <= s_axis_tuser;
                        end
                    end
                end
            endcase
        end
    end

    assign s_axis_tready = (REG_TYPE == 0) ? s_axis_tready_wire :
                          (REG_TYPE == 1) ? s_axis_tready_buffer :
                          s_axis_tready_skid;

    assign m_axis_tdata = reg_tdata;
    assign m_axis_tkeep = reg_tkeep;
    assign m_axis_tvalid = reg_tvalid;
    assign m_axis_tlast = LAST_ENABLE ? reg_tlast : 0;
    assign m_axis_tid = ID_ENABLE ? reg_tid : 0;
    assign m_axis_tdest = DEST_ENABLE ? reg_tdest : 0;
    assign m_axis_tuser = USER_ENABLE ? reg_tuser : 0;

endmodule
