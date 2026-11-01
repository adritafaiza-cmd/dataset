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
    wire [DATA_WIDTH-1:0]  reg_tdata;
    wire [KEEP_WIDTH-1:0]  reg_tkeep;
    wire                   reg_tvalid;
    wire                   reg_tlast;
    wire [ID_WIDTH-1:0]    reg_tid;
    wire [DEST_WIDTH-1:0]  reg_tdest;
    wire [USER_WIDTH-1:0]  reg_tuser;

    // Skid buffer registers
    reg [DATA_WIDTH-1:0]  skid_tdata;
    reg [KEEP_WIDTH-1:0]  skid_tkeep;
    reg                   skid_tvalid;
    reg                   skid_tlast;
    reg [ID_WIDTH-1:0]    skid_tid;
    reg [DEST_WIDTH-1:0]  skid_tdest;
    reg [USER_WIDTH-1:0]  skid_tuser;

    // Control signals
    wire s_axis_tready_int;
    wire m_axis_tvalid_int;
    wire accept;
    wire forward;

    // REG_TYPE: 0 = wire, 1 = buffer, 2 = skid buffer

    // Wire mode (REG_TYPE = 0): direct passthrough
    // Buffer mode (REG_TYPE = 1): single register
    // Skid buffer mode (REG_TYPE = 2): two-stage buffer

    generate
        if (REG_TYPE == 0) begin : gen_wire
            // Wire: direct connection
            assign m_axis_tdata  = s_axis_tdata;
            assign m_axis_tkeep  = s_axis_tkeep;
            assign m_axis_tvalid = s_axis_tvalid;
            assign m_axis_tlast  = s_axis_tlast;
            assign m_axis_tid    = s_axis_tid;
            assign m_axis_tdest  = s_axis_tdest;
            assign m_axis_tuser  = s_axis_tuser;
            assign s_axis_tready = m_axis_tready;
        end
        else if (REG_TYPE == 1) begin : gen_buffer
            // Single register buffer
            assign m_axis_tdata  = reg_tdata;
            assign m_axis_tkeep  = reg_tkeep;
            assign m_axis_tvalid = reg_tvalid;
            assign m_axis_tlast  = reg_tlast;
            assign m_axis_tid    = reg_tid;
            assign m_axis_tdest  = reg_tdest;
            assign m_axis_tuser  = reg_tuser;

            assign s_axis_tready = ~reg_tvalid | m_axis_tready;

            always @(posedge clk) begin
                if (rst) begin
                    reg_tvalid <= 1'b0;
                end else begin
                    if (s_axis_tvalid && s_axis_tready) begin
                        reg_tvalid <= 1'b1;
                        reg_tdata  <= s_axis_tdata;
                        reg_tkeep  <= s_axis_tkeep;
                        reg_tlast  <= s_axis_tlast;
                        reg_tid    <= s_axis_tid;
                        reg_tdest  <= s_axis_tdest;
                        reg_tuser  <= s_axis_tuser;
                    end else if (m_axis_tready && reg_tvalid) begin
                        reg_tvalid <= 1'b0;
                    end
                end
            end
        end
        else begin : gen_skid
            // Skid buffer: two-stage
            assign m_axis_tdata  = reg_tdata;
            assign m_axis_tkeep  = reg_tkeep;
            assign m_axis_tvalid = reg_tvalid;
            assign m_axis_tlast  = reg_tlast;
            assign m_axis_tid    = reg_tid;
            assign m_axis_tdest  = reg_tdest;
            assign m_axis_tuser  = reg_tuser;

            // Skid buffer logic
            // reg_tvalid indicates primary register has data
            // skid_tvalid indicates skid register has data

            // Accept new data if primary is empty or being drained
            assign s_axis_tready = ~reg_tvalid | (m_axis_tready & ~skid_tvalid);

            // Forward from primary to output
            assign forward = reg_tvalid & m_axis_tready;

            always @(posedge clk) begin
                if (rst) begin
                    reg_tvalid  <= 1'b0;
                    skid_tvalid <= 1'b0;
                end else begin
                    // Handle primary register
                    if (s_axis_tvalid && s_axis_tready) begin
                        // New data arrives
                        if (reg_tvalid) begin
                            // Primary is full, move to skid
                            skid_tdata  <= reg_tdata;
                            skid_tkeep  <= reg_tkeep;
                            skid_tlast  <= reg_tlast;
                            skid_tid    <= reg_tid;
                            skid_tdest  <= reg_tdest;
                            skid_tuser  <= reg_tuser;
                            skid_tvalid <= 1'b1;
                        end
                        // Load new data into primary
                        reg_tdata  <= s_axis_tdata;
                        reg_tkeep  <= s_axis_tkeep;
                        reg_tlast  <= s_axis_tlast;
                        reg_tid    <= s_axis_tid;
                        reg_tdest  <= s_axis_tdest;
                        reg_tuser  <= s_axis_tuser;
                        reg_tvalid <= 1'b1;
                    end else if (forward) begin
                        // Primary is being drained
                        if (skid_tvalid) begin
                            // Move skid data to primary
                            reg_tdata  <= skid_tdata;
                            reg_tkeep  <= skid_tkeep;
                            reg_tlast  <= skid_tlast;
                            reg_tid    <= skid_tid;
                            reg_tdest  <= skid_tdest;
                            reg_tuser  <= skid_tuser;
                            skid_tvalid <= 1'b0;
                        end else begin
                            reg_tvalid <= 1'b0;
                        end
                    end
                end
            end
        end
    endgenerate

endmodule
