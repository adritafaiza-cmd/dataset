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

    // Internal registers
    reg [DATA_WIDTH-1:0]  tdata_reg;
    reg [KEEP_WIDTH-1:0]  tkeep_reg;
    reg                   tvalid_reg;
    reg                   tlast_reg;
    reg [ID_WIDTH-1:0]    tid_reg;
    reg [DEST_WIDTH-1:0]  tdest_reg;
    reg [USER_WIDTH-1:0]  tuser_reg;

    // Internal signals
    wire tready_int;
    wire tvalid_int;

    // tready_int is asserted if REG_TYPE is 0 or if REG_TYPE is 2 and tvalid_reg is 0 (no data buffered).
    assign tready_int = (REG_TYPE == 0) || ((REG_TYPE == 2) && !tvalid_reg);

    // tvalid_int is asserted if REG_TYPE is 0 and s_axis_tvalid is 1, or if REG_TYPE is 1 or 2 and tvalid_reg is 1 (data buffered).
    assign tvalid_int = (REG_TYPE == 0 && s_axis_tvalid) || ((REG_TYPE == 1 || REG_TYPE == 2) && tvalid_reg);

    // Output signals driven by input signals when REG_TYPE is 0, or by the registers when REG_TYPE is 1 or 2.
    assign m_axis_tdata  = (REG_TYPE == 0) ? s_axis_tdata  : tdata_reg;
    assign m_axis_tkeep  = (REG_TYPE == 0) ? s_axis_tkeep  : tkeep_reg;
    assign m_axis_tvalid = tvalid_int;
    assign m_axis_tlast  = (REG_TYPE == 0) ? s_axis_tlast  : tlast_reg;
    assign m_axis_tid    = (REG_TYPE == 0) ? s_axis_tid    : tid_reg;
    assign m_axis_tdest  = (REG_TYPE == 0) ? s_axis_tdest  : tdest_reg;
    assign m_axis_tuser  = (REG_TYPE == 0) ? s_axis_tuser  : tuser_reg;

    // s_axis_tready is asserted if tready_int is high.
    assign s_axis_tready = tready_int;

    // Register logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tdata_reg  <= {DATA_WIDTH{1'b0}};
            tkeep_reg  <= {KEEP_WIDTH{1'b0}};
            tvalid_reg <= 1'b0;
            tlast_reg  <= 1'b0;
            tid_reg    <= {ID_WIDTH{1'b0}};
            tdest_reg  <= {DEST_WIDTH{1'b0}};
            tuser_reg  <= {USER_WIDTH{1'b0}};
        end else begin
            if (REG_TYPE == 1 || REG_TYPE == 2) begin
                // If REG_TYPE is 1 or 2 and tvalid_reg is 0 and s_axis_tvalid is 1, store input data in registers and set tvalid_reg to 1.
                if (!tvalid_reg && s_axis_tvalid) begin
                    tdata_reg  <= s_axis_tdata;
                    tkeep_reg  <= s_axis_tkeep;
                    tvalid_reg <= 1'b1;
                    tlast_reg  <= s_axis_tlast;
                    tid_reg    <= s_axis_tid;
                    tdest_reg  <= s_axis_tdest;
                    tuser_reg  <= s_axis_tuser;
                end
                // If REG_TYPE is 2 and tvalid_reg is 1 and m_axis_tready is 1, clear buffered data and set tvalid_reg to 0.
                else if (REG_TYPE == 2 && tvalid_reg && m_axis_tready) begin
                    tvalid_reg <= 1'b0;
                end
            end
        end
    end

endmodule
