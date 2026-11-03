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
     * Internal signals for the register slice
     */
    reg [DATA_WIDTH-1:0]          tdata_reg;
    reg [KEEP_WIDTH-1:0]          tkeep_reg;
    reg                           tvalid_reg;
    reg                           tlast_reg;
    reg [ID_WIDTH-1:0]            tid_reg;
    reg [DEST_WIDTH-1:0]          tdest_reg;
    reg [USER_WIDTH-1:0]          tuser_reg;
    reg                           tvalid_next;

    /*
     * Skid buffer logic
     */
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tdata_reg   <= 0;
            tkeep_reg   <= 0;
            tvalid_reg  <= 0;
            tlast_reg   <= 0;
            tid_reg     <= 0;
            tdest_reg   <= 0;
            tuser_reg   <= 0;
        end else begin
            if (REG_TYPE == 0) begin
                // Wire (no buffering)
                tdata_reg   <= s_axis_tdata;
                tkeep_reg   <= s_axis_tkeep;
                tvalid_reg  <= s_axis_tvalid;
                tlast_reg   <= s_axis_tlast;
                tid_reg     <= s_axis_tid;
                tdest_reg   <= s_axis_tdest;
                tuser_reg   <= s_axis_tuser;
            end else if (REG_TYPE == 1) begin
                // Simple buffer
                if (s_axis_tvalid && m_axis_tready) begin
                    tdata_reg   <= s_axis_tdata;
                    tkeep_reg   <= s_axis_tkeep;
                    tvalid_reg  <= s_axis_tvalid;
                    tlast_reg   <= s_axis_tlast;
                    tid_reg     <= s_axis_tid;
                    tdest_reg   <= s_axis_tdest;
                    tuser_reg   <= s_axis_tuser;
                end
            end else if (REG_TYPE == 2) begin
                // Skid buffer
                if (s_axis_tvalid && (m_axis_tready || !tvalid_reg)) begin
                    tdata_reg   <= s_axis_tdata;
                    tkeep_reg   <= s_axis_tkeep;
                    tvalid_reg  <= s_axis_tvalid;
                    tlast_reg   <= s_axis_tlast;
                    tid_reg     <= s_axis_tid;
                    tdest_reg   <= s_axis_tdest;
                    tuser_reg   <= s_axis_tuser;
                end
            end
        end
    end

    /*
     * Output assignments
     */
    assign s_axis_tready = (REG_TYPE == 0) ? m_axis_tready : (REG_TYPE == 1) ? m_axis_tready : !tvalid_reg;
    assign m_axis_tdata  = tdata_reg;
    assign m_axis_tkeep  = tkeep_reg;
    assign m_axis_tvalid = tvalid_reg;
    assign m_axis_tlast  = tlast_reg;
    assign m_axis_tid    = tid_reg;
    assign m_axis_tdest  = tdest_reg;
    assign m_axis_tuser  = tuser_reg;

endmodule
