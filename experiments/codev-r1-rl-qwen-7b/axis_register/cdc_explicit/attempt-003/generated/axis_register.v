module axis_register #(
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
) (
    input wire clk,
    input wire rst,
    // Input AXI Stream
    input wire [DATA_WIDTH-1:0] s_axis_tdata,
    input wire [KEEP_WIDTH-1:0] s_axis_tkeep,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    input wire s_axis_tlast,
    input wire [ID_WIDTH-1:0] s_axis_tid,
    input wire [DEST_WIDTH-1:0] s_axis_tdest,
    input wire [USER_WIDTH-1:0] s_axis_tuser,
    // Output AXI Stream
    output wire [DATA_WIDTH-1:0] m_axis_tdata,
    output wire [KEEP_WIDTH-1:0] m_axis_tkeep,
    output wire m_axis_tvalid,
    input wire m_axis_tready,
    output wire m_axis_tlast,
    output wire [ID_WIDTH-1:0] m_axis_tid,
    output wire [DEST_WIDTH-1:0] m_axis_tdest,
    output wire [USER_WIDTH-1:0] m_axis_tuser
);

generate
if (REG_TYPE == 0) begin : wire_type
    assign s_axis_tready = m_axis_tready;
    assign m_axis_tvalid = s_axis_tvalid;
    assign m_axis_tdata = s_axis_tdata;

    if (KEEP_ENABLE) begin
        assign m_axis_tkeep = s_axis_tkeep;
    end else begin
        assign m_axis_tkeep = 0;
    end

    if (LAST_ENABLE) begin
        assign m_axis_tlast = s_axis_tlast;
    end else begin
        assign m_axis_tlast = 0;
    end

    if (ID_ENABLE) begin
        assign m_axis_tid = s_axis_tid;
    end else begin
        assign m_axis_tid = 0;
    end

    if (DEST_ENABLE) begin
        assign m_axis_tdest = s_axis_tdest;
    end else begin
        assign m_axis_tdest = 0;
    end

    if (USER_ENABLE) begin
        assign m_axis_tuser = s_axis_tuser;
    end else begin
        assign m_axis_tuser = 0;
    end

end else if (REG_TYPE == 1) begin : simple_buffer
    reg [DATA_WIDTH-1:0] data_reg;
    reg [KEEP_WIDTH-1:0] keep_reg;
    reg last_reg;
    reg [ID_WIDTH-1:0] id_reg;
    reg [DEST_WIDTH-1:0] dest_reg;
    reg [USER_WIDTH-1:0] user_reg;
    reg valid_reg;

    assign s_axis_tready = ~valid_reg || m_axis_tready;

    always @(posedge clk) begin
        if (rst) begin
            valid_reg <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                data_reg <= s_axis_tdata;
                keep_reg <= s_axis_tkeep;
                last_reg <= s_axis_tlast;
                id_reg <= s_axis_tid;
                dest_reg <= s_axis_tdest;
                user_reg <= s_axis_tuser;
                valid_reg <= 1;
            end else if (m_axis_tready && valid_reg) begin
                valid_reg <= 0;
            end
        end
    end

    assign m_axis_tvalid = valid_reg;
    assign m_axis_tdata = data_reg;

    if (KEEP_ENABLE) begin
        assign m_axis_tkeep = keep_reg;
    end else begin
        assign m_axis_tkeep = 0;
    end

    if (LAST_ENABLE) begin
        assign m_axis_tlast = last_reg;
    end else begin
        assign m_axis_tlast = 0;
    end

    if (ID_ENABLE) begin
        assign m_axis_tid = id_reg;
    end else begin
        assign m_axis_tid = 0;
    end

    if (DEST_ENABLE) begin
        assign m_axis_tdest = dest_reg;
    end else begin
        assign m_axis_tdest = 0;
    end

    if (USER_ENABLE) begin
        assign m_axis_tuser = user_reg;
    end else begin
        assign m_axis_tuser = 0;
    end

end else if (REG_TYPE == 2) begin : skid_buffer
    reg [DATA_WIDTH-1:0] data_reg;
    reg [KEEP_WIDTH-1:0] keep_reg;
    reg last_reg;
    reg [ID_WIDTH-1:0] id_reg;
    reg [DEST_WIDTH-1:0] dest_reg;
    reg [USER_WIDTH-1:0] user_reg;
    reg valid_reg;

    reg [DATA_WIDTH-1:0] skid_data;
    reg [KEEP_WIDTH-1:0] skid_keep;
    reg skid_last;
    reg [ID_WIDTH-1:0] skid_id;
    reg [DEST_WIDTH-1:0] skid_dest;
    reg [USER_WIDTH-1:0] skid_user;
    reg skid_valid;

    assign s_axis_tready = (~valid_reg) || (m_axis_tready && ~skid_valid);

    always @(posedge clk) begin
        if (rst) begin
            valid_reg <= 0;
            skid_valid <= 0;
        end else begin
            if (m_axis_tready) begin
                if (valid_reg) begin
                    valid_reg <= 0;
                    if (skid_valid) begin
                        data_reg <= skid_data;
                        keep_reg <= skid_keep;
                        last_reg <= skid_last;
                        id_reg <= skid_id;
                        dest_reg <= skid_dest;
                        user_reg <= skid_user;
                        valid_reg <= 1;
                        skid_valid <= 0;
                    end
                end
            end

            if (s_axis_tvalid && s_axis_tready) begin
                if (valid_reg) begin
                    skid_data <= s_axis_tdata;
                    skid_keep <= s_axis_tkeep;
                    skid_last <= s_axis_tlast;
                    skid_id <= s_axis_tid;
                    skid_dest <= s_axis_tdest;
                    skid_user <= s_axis_tuser;
                    skid_valid <= 1;
                end else begin
                    data_reg <= s_axis_tdata;
                    keep_reg <= s_axis_tkeep;
                    last_reg <= s_axis_tlast;
                    id_reg <= s_axis_tid;
                    dest_reg <= s_axis_tdest;
                    user_reg <= s_axis_tuser;
                    valid_reg <= 1;
                end
            end
        end
    end

    assign m_axis_tvalid = valid_reg;
    assign m_axis_tdata = data_reg;

    if (KEEP_ENABLE) begin
        assign m_axis_tkeep = keep_reg;
    end else begin
        assign m_axis_tkeep = 0;
    end

    if (LAST_ENABLE) begin
        assign m_axis_tlast = last_reg;
    end else begin
        assign m_axis_tlast = 0;
    end

    if (ID_ENABLE) begin
        assign m_axis_tid = id_reg;
    end else begin
        assign m_axis_tid = 0;
    end

    if (DEST_ENABLE) begin
        assign m_axis_tdest = dest_reg;
    end else begin
        assign m_axis_tdest = 0;
    end

    if (USER_ENABLE) begin
        assign m_axis_tuser = user_reg;
    end else begin
        assign m_axis_tuser = 0;
    end

end
endgenerate

endmodule
