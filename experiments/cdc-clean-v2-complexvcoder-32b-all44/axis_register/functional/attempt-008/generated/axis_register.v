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

    /*
     * Internal registers
     */
    reg [DATA_WIDTH-1:0]          reg_tdata;
    reg [KEEP_WIDTH-1:0]          reg_tkeep;
    reg                           reg_tvalid;
    reg                           reg_tlast;
    reg [ID_WIDTH-1:0]            reg_tid;
    reg [DEST_WIDTH-1:0]          reg_tdest;
    reg [USER_WIDTH-1:0]          reg_tuser;
    reg                           reg_empty;
    reg                           reg_full;

    /*
     * Internal signals
     */
    wire                          next_tready;
    wire                          next_tvalid;

    /*
     * Assign output signals
     */
    assign s_axis_tready = (REG_TYPE == 0) ? m_axis_tready : (REG_TYPE == 1) ? reg_empty : ~reg_full;
    assign m_axis_tdata = (REG_TYPE == 0) ? s_axis_tdata : reg_tdata;
    assign m_axis_tkeep = (REG_TYPE == 0) ? s_axis_tkeep : reg_tkeep;
    assign m_axis_tvalid = (REG_TYPE == 0) ? s_axis_tvalid : reg_tvalid;
    assign m_axis_tlast = (REG_TYPE == 0) ? s_axis_tlast : reg_tlast;
    assign m_axis_tid = (REG_TYPE == 0) ? s_axis_tid : reg_tid;
    assign m_axis_tdest = (REG_TYPE == 0) ? s_axis_tdest : reg_tdest;
    assign m_axis_tuser = (REG_TYPE == 0) ? s_axis_tuser : reg_tuser;

    /*
     * Determine next tready and tvalid states
     */
    assign next_tready = (REG_TYPE == 0) ? m_axis_tready : (REG_TYPE == 1) ? reg_empty : ~reg_full;
    assign next_tvalid = (REG_TYPE == 0) ? s_axis_tvalid : reg_tvalid;

    /*
     * Register updates
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_tdata <= {DATA_WIDTH{1'b0}};
            reg_tkeep <= {KEEP_WIDTH{1'b0}};
            reg_tvalid <= 1'b0;
            reg_tlast <= 1'b0;
            reg_tid <= {ID_WIDTH{1'b0}};
            reg_tdest <= {DEST_WIDTH{1'b0}};
            reg_tuser <= {USER_WIDTH{1'b0}};
            reg_empty <= 1'b1;
            reg_full <= 1'b0;
        end else begin
            case (REG_TYPE)
                0: begin
                    // Wire, no buffering
                    reg_empty <= 1'b1;
                    reg_full <= 1'b0;
                end
                1: begin
                    // Simple buffer
                    if (next_tready && s_axis_tvalid) begin
                        reg_tdata <= s_axis_tdata;
                        reg_tkeep <= s_axis_tkeep;
                        reg_tvalid <= s_axis_tvalid;
                        reg_tlast <= s_axis_tlast;
                        reg_tid <= s_axis_tid;
                        reg_tdest <= s_axis_tdest;
                        reg_tuser <= s_axis_tuser;
                        reg_empty <= 1'b0;
                    end else if (m_axis_tready && reg_tvalid) begin
                        reg_tvalid <= 1'b0;
                        reg_empty <= 1'b1;
                    end
                end
                2: begin
                    // Skid buffer
                    if (next_tready && s_axis_tvalid && ~reg_tvalid) begin
                        reg_tdata <= s_axis_tdata;
                        reg_tkeep <= s_axis_tkeep;
                        reg_tvalid <= s_axis_tvalid;
                        reg_tlast <= s_axis_tlast;
                        reg_tid <= s_axis_tid;
                        reg_tdest <= s_axis_tdest;
                        reg_tuser <= s_axis_tuser;
                        reg_empty <= 1'b0;
                    end else if (m_axis_tready && reg_tvalid) begin
                        reg_tvalid <= 1'b0;
                        reg_empty <= 1'b1;
                    end
                    reg_full <= reg_tvalid && ~next_tready;
                end
                default: begin
                    // Default case should not occur
                end
            endcase
        end
    end

endmodule
