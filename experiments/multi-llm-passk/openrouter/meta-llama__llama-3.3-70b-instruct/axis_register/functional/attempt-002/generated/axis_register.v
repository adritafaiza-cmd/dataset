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

reg [DATA_WIDTH-1:0] data_reg;
reg [KEEP_WIDTH-1:0] keep_reg;
reg last_reg;
reg [ID_WIDTH-1:0] id_reg;
reg [DEST_WIDTH-1:0] dest_reg;
reg [USER_WIDTH-1:0] user_reg;
reg valid_reg;

always @(posedge clk or posedge rst)
begin
    if (rst)
    begin
        data_reg <= 0;
        keep_reg <= 0;
        last_reg <= 0;
        id_reg <= 0;
        dest_reg <= 0;
        user_reg <= 0;
        valid_reg <= 0;
    end
    else
    begin
        if (REG_TYPE == 0)
        begin
            // wire
            data_reg <= s_axis_tdata;
            keep_reg <= s_axis_tkeep;
            last_reg <= s_axis_tlast;
            id_reg <= s_axis_tid;
            dest_reg <= s_axis_tdest;
            user_reg <= s_axis_tuser;
            valid_reg <= s_axis_tvalid;
        end
        else if (REG_TYPE == 1)
        begin
            // simple buffer
            if (s_axis_tvalid && s_axis_tready)
            begin
                data_reg <= s_axis_tdata;
                keep_reg <= s_axis_tkeep;
                last_reg <= s_axis_tlast;
                id_reg <= s_axis_tid;
                dest_reg <= s_axis_tdest;
                user_reg <= s_axis_tuser;
                valid_reg <= 1'b1;
            end
            else if (m_axis_tready)
            begin
                valid_reg <= 1'b0;
            end
        end
        else if (REG_TYPE == 2)
        begin
            // skid buffer
            if (s_axis_tvalid && s_axis_tready)
            begin
                data_reg <= s_axis_tdata;
                keep_reg <= s_axis_tkeep;
                last_reg <= s_axis_tlast;
                id_reg <= s_axis_tid;
                dest_reg <= s_axis_tdest;
                user_reg <= s_axis_tuser;
                valid_reg <= 1'b1;
            end
            else if (m_axis_tready && valid_reg)
            begin
                valid_reg <= 1'b0;
            end
        end
    end
end

assign s_axis_tready = (REG_TYPE == 0) ? 1'b1 : (valid_reg ? m_axis_tready : 1'b1);
assign m_axis_tdata = data_reg;
assign m_axis_tkeep = keep_reg;
assign m_axis_tvalid = valid_reg;
assign m_axis_tlast = last_reg;
assign m_axis_tid = id_reg;
assign m_axis_tdest = dest_reg;
assign m_axis_tuser = user_reg;

endmodule
