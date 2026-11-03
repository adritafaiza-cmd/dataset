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

    reg [DATA_WIDTH-1:0]          tdata_reg;
    reg [KEEP_WIDTH-1:0]          tkeep_reg;
    reg                           tvalid_reg;
    reg                           tlast_reg;
    reg [ID_WIDTH-1:0]            tid_reg;
    reg [DEST_WIDTH-1:0]          tdest_reg;
    reg [USER_WIDTH-1:0]          tuser_reg;
    reg                           tready_int;
    reg                           tready_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tdata_reg  <= {DATA_WIDTH{1'b0}};
            tkeep_reg  <= {KEEP_WIDTH{1'b0}};
            tvalid_reg <= 1'b0;
            tlast_reg  <= 1'b0;
            tid_reg    <= {ID_WIDTH{1'b0}};
            tdest_reg  <= {DEST_WIDTH{1'b0}};
            tuser_reg  <= {USER_WIDTH{1'b0}};
            tready_reg <= 1'b0;
        end else begin
            if (REG_TYPE == 2) begin
                if (tvalid_reg == 1'b0) begin
                    tready_reg <= m_axis_tready;
                end else begin
                    tready_reg <= 1'b0;
                end
            end

            if (s_axis_tvalid && tready_int) begin
                tdata_reg  <= s_axis_tdata;
                tkeep_reg  <= s_axis_tkeep;
                tvalid_reg <= 1'b1;
                tlast_reg  <= s_axis_tlast;
                if (ID_ENABLE)  tid_reg   <= s_axis_tid;
                if (DEST_ENABLE) tdest_reg <= s_axis_tdest;
                if (USER_ENABLE) tuser_reg <= s_axis_tuser;
            end

            if (m_axis_tready && tvalid_reg) begin
                tvalid_reg <= 1'b0;
            end
        end
    end

    always @(*) begin
        case (REG_TYPE)
            0: tready_int = m_axis_tready; // Wire mode
            1: tready_int = 1'b1;         // Buffer mode
            2: tready_int = (tready_reg == 1'b0) || (m_axis_tready && tready_reg); // Skid buffer mode
            default: tready_int = 1'b0;
        endcase
    end

    assign s_axis_tready = tready_int;
    assign m_axis_tdata  = tdata_reg;
    assign m_axis_tkeep  = tkeep_reg;
    assign m_axis_tvalid = tvalid_reg;
    assign m_axis_tlast  = tlast_reg;
    assign m_axis_tid    = ID_ENABLE ? tid_reg : {ID_WIDTH{1'b0}};
    assign m_axis_tdest  = DEST_ENABLE ? tdest_reg : {DEST_WIDTH{1'b0}};
    assign m_axis_tuser  = USER_ENABLE ? tuser_reg : {USER_WIDTH{1'b0}};

endmodule
