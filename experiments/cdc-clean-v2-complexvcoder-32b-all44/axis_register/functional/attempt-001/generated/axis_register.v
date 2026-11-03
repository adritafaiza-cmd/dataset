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
    reg                   reg_empty;
    reg                   reg_full;
    wire                  s_axis_tready_int;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_tdata  <= 0;
            reg_tkeep  <= 0;
            reg_tvalid <= 0;
            reg_tlast  <= 0;
            reg_tid    <= 0;
            reg_tdest  <= 0;
            reg_tuser  <= 0;
            reg_empty  <= 1;
            reg_full   <= 0;
        end else begin
            case (REG_TYPE)
                0: begin // Wire
                    reg_tdata  <= s_axis_tdata;
                    reg_tkeep  <= s_axis_tkeep;
                    reg_tvalid <= s_axis_tvalid;
                    reg_tlast  <= s_axis_tlast;
                    reg_tid    <= s_axis_tid;
                    reg_tdest  <= s_axis_tdest;
                    reg_tuser  <= s_axis_tuser;
                    reg_empty  <= ~s_axis_tvalid;
                    reg_full   <= 0;
                end
                1: begin // Simple Buffer
                    if (s_axis_tvalid && s_axis_tready_int) begin
                        reg_tdata  <= s_axis_tdata;
                        reg_tkeep  <= s_axis_tkeep;
                        reg_tlast  <= s_axis_tlast;
                        reg_tid    <= s_axis_tid;
                        reg_tdest  <= s_axis_tdest;
                        reg_tuser  <= s_axis_tuser;
                    end
                    reg_tvalid <= s_axis_tvalid && s_axis_tready_int;
                    reg_empty  <= ~reg_tvalid;
                    reg_full   <= reg_tvalid;
                end
                2: begin // Skid Buffer
                    if (s_axis_tvalid && s_axis_tready_int && !reg_full) begin
                        reg_tdata  <= s_axis_tdata;
                        reg_tkeep  <= s_axis_tkeep;
                        reg_tlast  <= s_axis_tlast;
                        reg_tid    <= s_axis_tid;
                        reg_tdest  <= s_axis_tdest;
                        reg_tuser  <= s_axis_tuser;
                        reg_full   <= 1;
                    end
                    if (m_axis_tready && reg_full) begin
                        reg_full <= 0;
                    end
                    reg_tvalid <= reg_full;
                    reg_empty  <= ~reg_full;
                end
                default: begin
                    reg_tdata  <= 0;
                    reg_tkeep  <= 0;
                    reg_tvalid <= 0;
                    reg_tlast  <= 0;
                    reg_tid    <= 0;
                    reg_tdest  <= 0;
                    reg_tuser  <= 0;
                    reg_empty  <= 1;
                    reg_full   <= 0;
                end
            endcase
        end
    end

    assign s_axis_tready_int = REG_TYPE == 0 || (REG_TYPE == 1 && !reg_tvalid) || (REG_TYPE == 2 && !reg_full);
    assign s_axis_tready     = s_axis_tready_int;

    assign m_axis_tdata  = reg_tdata;
    assign m_axis_tkeep  = reg_tkeep;
    assign m_axis_tvalid = reg_tvalid;
    assign m_axis_tlast  = reg_tlast;
    assign m_axis_tid    = reg_tid;
    assign m_axis_tdest  = reg_tdest;
    assign m_axis_tuser  = reg_tuser;

endmodule
