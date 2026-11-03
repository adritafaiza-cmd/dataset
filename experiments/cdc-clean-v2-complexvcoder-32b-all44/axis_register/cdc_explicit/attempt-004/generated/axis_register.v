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

    // Internal registers for simple buffer and skid buffer
    reg [DATA_WIDTH-1:0]  reg_tdata;
    reg [KEEP_WIDTH-1:0]  reg_tkeep;
    reg                   reg_tvalid;
    reg                   reg_tlast;
    reg [ID_WIDTH-1:0]    reg_tid;
    reg [DEST_WIDTH-1:0]  reg_tdest;
    reg [USER_WIDTH-1:0]  reg_tuser;

    // Skid buffer registers
    reg [DATA_WIDTH-1:0]  skid_tdata;
    reg [KEEP_WIDTH-1:0]  skid_tkeep;
    reg                   skid_tvalid;
    reg                   skid_tlast;
    reg [ID_WIDTH-1:0]    skid_tid;
    reg [DEST_WIDTH-1:0]  skid_tdest;
    reg [USER_WIDTH-1:0]  skid_tuser;

    // Ready signals
    wire s_axis_tready_wire;
    wire s_axis_tready_simple;
    wire s_axis_tready_skid;

    // Combinational logic for ready signals
    assign s_axis_tready_wire = m_axis_tready;
    assign s_axis_tready_simple = ~reg_tvalid | m_axis_tready;
    assign s_axis_tready_skid = ~reg_tvalid | (~skid_tvalid & m_axis_tready);

    // Output assignments based on REG_TYPE
    generate
        if (REG_TYPE == 0) begin : wire_mode
            assign s_axis_tready = s_axis_tready_wire;
            assign m_axis_tdata = s_axis_tdata;
            assign m_axis_tkeep = KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b1}};
            assign m_axis_tvalid = s_axis_tvalid;
            assign m_axis_tlast = LAST_ENABLE ? s_axis_tlast : 1'b0;
            assign m_axis_tid = ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}};
            assign m_axis_tdest = DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}};
            assign m_axis_tuser = USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}};
        end else if (REG_TYPE == 1) begin : simple_buffer_mode
            assign s_axis_tready = s_axis_tready_simple;
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    reg_tvalid <= 1'b0;
                end else begin
                    if (s_axis_tvalid && s_axis_tready_simple) begin
                        reg_tdata <= s_axis_tdata;
                        reg_tkeep <= KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b1}};
                        reg_tlast <= LAST_ENABLE ? s_axis_tlast : 1'b0;
                        reg_tid <= ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}};
                        reg_tdest <= DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}};
                        reg_tuser <= USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}};
                        reg_tvalid <= 1'b1;
                    end else if (m_axis_tready) begin
                        reg_tvalid <= 1'b0;
                    end
                end
            end
            assign m_axis_tdata = reg_tdata;
            assign m_axis_tkeep = reg_tkeep;
            assign m_axis_tvalid = reg_tvalid;
            assign m_axis_tlast = reg_tlast;
            assign m_axis_tid = reg_tid;
            assign m_axis_tdest = reg_tdest;
            assign m_axis_tuser = reg_tuser;
        end else if (REG_TYPE == 2) begin : skid_buffer_mode
            assign s_axis_tready = s_axis_tready_skid;
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    reg_tvalid <= 1'b0;
                    skid_tvalid <= 1'b0;
                end else begin
                    if (s_axis_tvalid && s_axis_tready_skid) begin
                        if (m_axis_tready) begin
                            reg_tdata <= s_axis_tdata;
                            reg_tkeep <= KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b1}};
                            reg_tlast <= LAST_ENABLE ? s_axis_tlast : 1'b0;
                            reg_tid <= ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}};
                            reg_tdest <= DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}};
                            reg_tuser <= USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}};
                            reg_tvalid <= 1'b1;
                        end else begin
                            skid_tdata <= s_axis_tdata;
                            skid_tkeep <= KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b1}};
                            skid_tlast <= LAST_ENABLE ? s_axis_tlast : 1'b0;
                            skid_tid <= ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}};
                            skid_tdest <= DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}};
                            skid_tuser <= USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}};
                            skid_tvalid <= 1'b1;
                        end
                    end else if (m_axis_tready && reg_tvalid) begin
                        reg_tvalid <= 1'b0;
                        if (skid_tvalid) begin
                            reg_tdata <= skid_tdata;
                            reg_tkeep <= skid_tkeep;
                            reg_tlast <= skid_tlast;
                            reg_tid <= skid_tid;
                            reg_tdest <= skid_tdest;
                            reg_tuser <= skid_tuser;
                            reg_tvalid <= 1'b1;
                            skid_tvalid <= 1'b0;
                        end
                    end
                end
            end
            assign m_axis_tdata = reg_tdata;
            assign m_axis_tkeep = reg_tkeep;
            assign m_axis_tvalid = reg_tvalid;
            assign m_axis_tlast = reg_tlast;
            assign m_axis_tid = reg_tid;
            assign m_axis_tdest = reg_tdest;
            assign m_axis_tuser = reg_tuser;
        end
    endgenerate

endmodule
