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

    reg [DATA_WIDTH-1:0]  skid_tdata;
    reg [KEEP_WIDTH-1:0]  skid_tkeep;
    reg                   skid_tvalid;
    reg                   skid_tlast;
    reg [ID_WIDTH-1:0]    skid_tid;
    reg [DEST_WIDTH-1:0]  skid_tdest;
    reg [USER_WIDTH-1:0]  skid_tuser;

    reg                   empty;

    // Wire type
    wire [DATA_WIDTH-1:0]  wire_tdata;
    wire [KEEP_WIDTH-1:0]  wire_tkeep;
    wire                   wire_tvalid;
    wire                   wire_tlast;
    wire [ID_WIDTH-1:0]    wire_tid;
    wire [DEST_WIDTH-1:0]  wire_tdest;
    wire [USER_WIDTH-1:0]  wire_tuser;

    assign wire_tdata  = s_axis_tdata;
    assign wire_tkeep  = s_axis_tkeep;
    assign wire_tvalid = s_axis_tvalid;
    assign wire_tlast  = s_axis_tlast;
    assign wire_tid    = s_axis_tid;
    assign wire_tdest  = s_axis_tdest;
    assign wire_tuser  = s_axis_tuser;

    // Simple buffer type
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_tdata  <= {DATA_WIDTH{1'b0}};
            reg_tkeep  <= {KEEP_WIDTH{1'b0}};
            reg_tvalid <= 1'b0;
            reg_tlast  <= 1'b0;
            reg_tid    <= {ID_WIDTH{1'b0}};
            reg_tdest  <= {DEST_WIDTH{1'b0}};
            reg_tuser  <= {USER_WIDTH{1'b0}};
        end else if (s_axis_tvalid && m_axis_tready) begin
            reg_tdata  <= s_axis_tdata;
            reg_tkeep  <= s_axis_tkeep;
            reg_tvalid <= s_axis_tvalid;
            reg_tlast  <= s_axis_tlast;
            reg_tid    <= s_axis_tid;
            reg_tdest  <= s_axis_tdest;
            reg_tuser  <= s_axis_tuser;
        end
    end

    // Skid buffer type
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            skid_tdata  <= {DATA_WIDTH{1'b0}};
            skid_tkeep  <= {KEEP_WIDTH{1'b0}};
            skid_tvalid <= 1'b0;
            skid_tlast  <= 1'b0;
            skid_tid    <= {ID_WIDTH{1'b0}};
            skid_tdest  <= {DEST_WIDTH{1'b0}};
            skid_tuser  <= {USER_WIDTH{1'b0}};
            empty       <= 1'b1;
        end else begin
            if (s_axis_tvalid && !reg_tvalid) begin
                skid_tdata  <= s_axis_tdata;
                skid_tkeep  <= s_axis_tkeep;
                skid_tlast  <= s_axis_tlast;
                skid_tid    <= s_axis_tid;
                skid_tdest  <= s_axis_tdest;
                skid_tuser  <= s_axis_tuser;
                skid_tvalid <= 1'b1;
                empty       <= 1'b0;
            end else if (m_axis_tready && reg_tvalid) begin
                skid_tvalid <= 1'b0;
                empty       <= 1'b1;
            end
        end
    end

    // Output assignments based on REG_TYPE
    generate
        if (REG_TYPE == 0) begin : wire_type
            assign s_axis_tready = m_axis_tready;
            assign m_axis_tdata  = wire_tdata;
            assign m_axis_tkeep  = wire_tkeep;
            assign m_axis_tvalid = wire_tvalid;
            assign m_axis_tlast  = wire_tlast;
            assign m_axis_tid    = wire_tid;
            assign m_axis_tdest  = wire_tdest;
            assign m_axis_tuser  = wire_tuser;
        end else if (REG_TYPE == 1) begin : simple_buffer
            assign s_axis_tready = m_axis_tready;
            assign m_axis_tdata  = reg_tdata;
            assign m_axis_tkeep  = reg_tkeep;
            assign m_axis_tvalid = reg_tvalid;
            assign m_axis_tlast  = reg_tlast;
            assign m_axis_tid    = reg_tid;
            assign m_axis_tdest  = reg_tdest;
            assign m_axis_tuser  = reg_tuser;
        end else if (REG_TYPE == 2) begin : skid_buffer
            assign s_axis_tready = m_axis_tready || !reg_tvalid;
            assign m_axis_tdata  = reg_tvalid ? reg_tdata  : skid_tdata;
            assign m_axis_tkeep  = reg_tvalid ? reg_tkeep  : skid_tkeep;
            assign m_axis_tvalid = reg_tvalid || skid_tvalid;
            assign m_axis_tlast  = reg_tvalid ? reg_tlast  : skid_tlast;
            assign m_axis_tid    = reg_tvalid ? reg_tid    : skid_tid;
            assign m_axis_tdest  = reg_tvalid ? reg_tdest  : skid_tdest;
            assign m_axis_tuser  = reg_tvalid ? reg_tuser  : skid_tuser;
        end
    endgenerate

endmodule
