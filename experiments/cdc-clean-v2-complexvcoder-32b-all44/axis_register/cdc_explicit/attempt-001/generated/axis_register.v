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

    wire s_axis_tready_int;
    wire m_axis_tvalid_int;

    axis_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_ENABLE(KEEP_ENABLE),
        .KEEP_WIDTH(KEEP_WIDTH),
        .LAST_ENABLE(LAST_ENABLE),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH),
        .REG_TYPE(REG_TYPE)
    ) buffer_inst (
        .clk(clk),
        .rst(rst),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tkeep(s_axis_tkeep),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready_int),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tid(s_axis_tid),
        .s_axis_tdest(s_axis_tdest),
        .s_axis_tuser(s_axis_tuser),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tkeep(m_axis_tkeep),
        .m_axis_tvalid(m_axis_tvalid_int),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tid(m_axis_tid),
        .m_axis_tdest(m_axis_tdest),
        .m_axis_tuser(m_axis_tuser)
    );

    assign s_axis_tready = s_axis_tready_int;
    assign m_axis_tvalid = m_axis_tvalid_int;

endmodule

module axis_buffer #(
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

    reg [DATA_WIDTH-1:0] tdata_reg;
    reg [KEEP_WIDTH-1:0] tkeep_reg;
    reg                  tvalid_reg;
    reg                  tlast_reg;
    reg [ID_WIDTH-1:0]   tid_reg;
    reg [DEST_WIDTH-1:0] tdest_reg;
    reg [USER_WIDTH-1:0] tuser_reg;
    reg                  buffer_full;
    reg                  buffer_empty;

    wire s_axis_tready_int;
    wire m_axis_tvalid_int;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tdata_reg  <= {DATA_WIDTH{1'b0}};
            tkeep_reg  <= {KEEP_WIDTH{1'b0}};
            tvalid_reg <= 1'b0;
            tlast_reg  <= 1'b0;
            tid_reg    <= {ID_WIDTH{1'b0}};
            tdest_reg  <= {DEST_WIDTH{1'b0}};
            tuser_reg  <= {USER_WIDTH{1'b0}};
            buffer_full <= 1'b0;
            buffer_empty <= 1'b1;
        end else begin
            case (REG_TYPE)
                0: begin // Wire connection, no buffering
                    tdata_reg  <= s_axis_tdata;
                    tkeep_reg  <= s_axis_tkeep;
                    tvalid_reg <= s_axis_tvalid;
                    tlast_reg  <= s_axis_tlast;
                    tid_reg    <= s_axis_tid;
                    tdest_reg  <= s_axis_tdest;
                    tuser_reg  <= s_axis_tuser;
                    buffer_full <= 1'b0;
                    buffer_empty <= 1'b1;
                end
                1: begin // Simple buffer with no backpressure handling
                    if (s_axis_tvalid && !buffer_full) begin
                        tdata_reg  <= s_axis_tdata;
                        tkeep_reg  <= s_axis_tkeep;
                        tvalid_reg <= 1'b1;
                        tlast_reg  <= s_axis_tlast;
                        tid_reg    <= s_axis_tid;
                        tdest_reg  <= s_axis_tdest;
                        tuser_reg  <= s_axis_tuser;
                        buffer_full <= 1'b1;
                        buffer_empty <= 1'b0;
                    end else if (m_axis_tready && buffer_full) begin
                        tvalid_reg <= 1'b0;
                        buffer_full <= 1'b0;
                        buffer_empty <= 1'b1;
                    end
                end
                2: begin // Skid buffer to prevent data loss on output stall
                    if (s_axis_tvalid && !buffer_full && m_axis_tready) begin
                        tdata_reg  <= s_axis_tdata;
                        tkeep_reg  <= s_axis_tkeep;
                        tvalid_reg <= 1'b1;
                        tlast_reg  <= s_axis_tlast;
                        tid_reg    <= s_axis_tid;
                        tdest_reg  <= s_axis_tdest;
                        tuser_reg  <= s_axis_tuser;
                        buffer_full <= 1'b1;
                        buffer_empty <= 1'b0;
                    end else if (m_axis_tready && buffer_full) begin
                        tvalid_reg <= 1'b0;
                        buffer_full <= 1'b0;
                        buffer_empty <= 1'b1;
                    end else if (s_axis_tvalid && buffer_full) begin
                        // Do nothing, skid the input
                    end
                end
            endcase
        end
    end

    assign s_axis_tready = (REG_TYPE == 0) ? m_axis_tready : (!buffer_full);
    assign m_axis_tvalid = (REG_TYPE == 0) ? s_axis_tvalid : tvalid_reg;
    assign m_axis_tdata = tdata_reg;
    assign m_axis_tkeep = tkeep_reg;
    assign m_axis_tlast = tlast_reg;
    assign m_axis_tid = tid_reg;
    assign m_axis_tdest = tdest_reg;
    assign m_axis_tuser = tuser_reg;

endmodule
