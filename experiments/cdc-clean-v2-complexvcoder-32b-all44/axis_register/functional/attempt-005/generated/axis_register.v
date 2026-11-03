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
    reg [DATA_WIDTH-1:0]  tdata_reg;
    reg [KEEP_WIDTH-1:0]  tkeep_reg;
    reg                   tvalid_reg;
    reg                   tlast_reg;
    reg [ID_WIDTH-1:0]    tid_reg;
    reg [DEST_WIDTH-1:0]  tdest_reg;
    reg [USER_WIDTH-1:0]  tuser_reg;
    reg                   tready_int;
    reg                   tvalid_int;

    // Assign output ports
    assign m_axis_tdata = tdata_reg;
    assign m_axis_tkeep = tkeep_reg;
    assign m_axis_tvalid = tvalid_reg;
    assign m_axis_tlast = tlast_reg;
    assign m_axis_tid = tid_reg;
    assign m_axis_tdest = tdest_reg;
    assign m_axis_tuser = tuser_reg;

    // Assign s_axis_tready
    assign s_axis_tready = tready_int;

    // Main logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tdata_reg <= 0;
            tkeep_reg <= 0;
            tvalid_reg <= 0;
            tlast_reg <= 0;
            tid_reg <= 0;
            tdest_reg <= 0;
            tuser_reg <= 0;
            tready_int <= 1;
            tvalid_int <= 0;
        end else begin
            case (REG_TYPE)
                0: begin // Wire
                    tready_int <= 1;
                    tvalid_int <= s_axis_tvalid;
                    tdata_reg <= s_axis_tdata;
                    tkeep_reg <= s_axis_tkeep;
                    tlast_reg <= s_axis_tlast;
                    tid_reg <= s_axis_tid;
                    tdest_reg <= s_axis_tdest;
                    tuser_reg <= s_axis_tuser;
                end
                1: begin // Simple buffer
                    if (s_axis_tvalid && tready_int) begin
                        tdata_reg <= s_axis_tdata;
                        tkeep_reg <= s_axis_tkeep;
                        tlast_reg <= s_axis_tlast;
                        tid_reg <= s_axis_tid;
                        tdest_reg <= s_axis_tdest;
                        tuser_reg <= s_axis_tuser;
                        tvalid_int <= 1;
                    end
                    if (m_axis_tready && tvalid_int) begin
                        tvalid_int <= 0;
                    end
                    tready_int <= !tvalid_int;
                end
                2: begin // Skid buffer
                    if (s_axis_tvalid && tready_int) begin
                        tdata_reg <= s_axis_tdata;
                        tkeep_reg <= s_axis_tkeep;
                        tlast_reg <= s_axis_tlast;
                        tid_reg <= s_axis_tid;
                        tdest_reg <= s_axis_tdest;
                        tuser_reg <= s_axis_tuser;
                        tvalid_int <= 1;
                    end
                    if (m_axis_tready && tvalid_int) begin
                        tvalid_int <= 0;
                    end
                    tready_int <= !tvalid_int || m_axis_tready;
                end
                default: begin
                    tready_int <= 1;
                    tvalid_int <= 0;
                end
            endcase
        end
    end

endmodule
