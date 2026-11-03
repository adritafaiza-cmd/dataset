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
    reg [DATA_WIDTH-1:0]  reg_tdata;
    reg [KEEP_WIDTH-1:0]  reg_tkeep;
    reg                   reg_tvalid;
    reg                   reg_tlast;
    reg [ID_WIDTH-1:0]    reg_tid;
    reg [DEST_WIDTH-1:0]  reg_tdest;
    reg [USER_WIDTH-1:0]  reg_tuser;
    reg                   stall;
    reg                   next_reg_tvalid;
    reg [DATA_WIDTH-1:0]  next_reg_tdata;
    reg [KEEP_WIDTH-1:0]  next_reg_tkeep;
    reg                   next_reg_tlast;
    reg [ID_WIDTH-1:0]    next_reg_tid;
    reg [DEST_WIDTH-1:0]  next_reg_tdest;
    reg [USER_WIDTH-1:0]  next_reg_tuser;

    // Skid buffer implementation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_tdata <= 0;
            reg_tkeep <= 0;
            reg_tvalid <= 0;
            reg_tlast <= 0;
            reg_tid <= 0;
            reg_tdest <= 0;
            reg_tuser <= 0;
            stall <= 0;
        end else begin
            if (stall) begin
                // Hold the current data when stalled
                reg_tdata <= reg_tdata;
                reg_tkeep <= reg_tkeep;
                reg_tvalid <= reg_tvalid;
                reg_tlast <= reg_tlast;
                reg_tid <= reg_tid;
                reg_tdest <= reg_tdest;
                reg_tuser <= reg_tuser;
            end else begin
                // Update the register with new data
                reg_tdata <= next_reg_tdata;
                reg_tkeep <= next_reg_tkeep;
                reg_tvalid <= next_reg_tvalid;
                reg_tlast <= next_reg_tlast;
                reg_tid <= next_reg_tid;
                reg_tdest <= next_reg_tdest;
                reg_tuser <= next_reg_tuser;
            end
        end
    end

    // Determine stall condition
    always @(*) begin
        stall = reg_tvalid && !m_axis_tready;
    end

    // Determine next register values
    always @(*) begin
        next_reg_tvalid = s_axis_tvalid && !stall;
        next_reg_tdata = s_axis_tdata;
        next_reg_tkeep = KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b1}};
        next_reg_tlast = LAST_ENABLE ? s_axis_tlast : 1'b0;
        next_reg_tid = ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}};
        next_reg_tdest = DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}};
        next_reg_tuser = USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}};
    end

    // Output assignments
    assign s_axis_tready = !stall;
    assign m_axis_tdata = reg_tdata;
    assign m_axis_tkeep = reg_tkeep;
    assign m_axis_tvalid = reg_tvalid;
    assign m_axis_tlast = reg_tlast;
    assign m_axis_tid = reg_tid;
    assign m_axis_tdest = reg_tdest;
    assign m_axis_tuser = reg_tuser;

endmodule
