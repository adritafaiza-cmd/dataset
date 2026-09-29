module axis_adapter #(
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_ENABLE = (S_DATA_WIDTH>8),
    parameter S_KEEP_WIDTH = ((S_DATA_WIDTH+7)/8),
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_ENABLE = (M_DATA_WIDTH>8),
    parameter M_KEEP_WIDTH = ((M_DATA_WIDTH+7)/8),
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1
) (
    input wire clk,
    input wire rst,
    // AXI input
    input wire [S_DATA_WIDTH-1:0] s_axis_tdata,
    input wire [S_KEEP_WIDTH-1:0] s_axis_tkeep,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    input wire s_axis_tlast,
    input wire [ID_WIDTH-1:0] s_axis_tid,
    input wire [DEST_WIDTH-1:0] s_axis_tdest,
    input wire [USER_WIDTH-1:0] s_axis_tuser,
    // AXI output
    output wire [M_DATA_WIDTH-1:0] m_axis_tdata,
    output wire [M_KEEP_WIDTH-1:0] m_axis_tkeep,
    output wire m_axis_tvalid,
    input wire m_axis_tready,
    output wire m_axis_tlast,
    output wire [ID_WIDTH-1:0] m_axis_tid,
    output wire [DEST_WIDTH-1:0] m_axis_tdest,
    output wire [USER_WIDTH-1:0] m_axis_tuser
);

    localparam RATIO = M_DATA_WIDTH / S_DATA_WIDTH;

    reg [M_DATA_WIDTH-1:0] m_data_reg;
    reg [S_KEEP_WIDTH-1:0] m_keep_reg;
    reg m_valid_reg;
    reg m_tlast_reg;

    generate
        if (ID_ENABLE) begin
            reg [ID_WIDTH-1:0] m_id_reg;
            assign m_axis_tid = m_id_reg;
        end else begin
            assign m_axis_tid = 0;
        end

        if (DEST_ENABLE) begin
            reg [DEST_WIDTH-1:0] m_dest_reg;
            assign m_axis_tdest = m_dest_reg;
        end else begin
            assign m_axis_tdest = 0;
        end

        if (USER_ENABLE) begin
            reg [USER_WIDTH-1:0] m_user_reg;
            assign m_axis_tuser = m_user_reg;
        end else begin
            assign m_axis_tuser = 0;
        end
    endgenerate

    reg [$clog2(RATIO)-1:0] count;

    assign m_axis_tdata = m_data_reg;
    assign m_axis_tvalid = m_valid_reg;
    assign m_axis_tlast = m_tlast_reg;
    assign m_axis_tkeep = M_KEEP_ENABLE ? m_keep_reg : 0;

    assign s_axis_tready = (count < RATIO) && m_axis_tready;

    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
            m_valid_reg <= 0;
            m_tlast_reg <= 0;
            m_data_reg <= 0;
            m_keep_reg <= 0;
            generate
                if (ID_ENABLE) begin
                    m_id_reg <= 0;
                end
                if (DEST_ENABLE) begin
                    m_dest_reg <= 0;
                end
                if (USER_ENABLE) begin
                    m_user_reg <= 0;
                end
            endgenerate
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                m_data_reg <= {m_data_reg[S_DATA_WIDTH-1:0], s_axis_tdata};
                m_keep_reg <= {m_keep_reg[S_KEEP_WIDTH-1:0], s_axis_tkeep};
                count <= count + 1;

                generate
                    if (ID_ENABLE) begin
                        m_id_reg <= s_axis_tid;
                    end
                    if (DEST_ENABLE) begin
                        m_dest_reg <= s_axis_tdest;
                    end
                    if (USER_ENABLE) begin
                        m_user_reg <= s_axis_tuser;
                    end
                endgenerate

                if (count == RATIO - 1) begin
                    m_valid_reg <= 1;
                    m_tlast_reg <= s_axis_tlast;
                    count <= 0;
                end else begin
                    m_valid_reg <= 0;
                end
            end

            if (m_axis_tready && m_valid_reg) begin
                m_valid_reg <= 0;
            end
        end
    end

endmodule
