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
    wire                   reg_tready;

    // Wire mode (REG_TYPE == 0)
    wire wire_mode = (REG_TYPE == 0);
    // Simple buffer mode (REG_TYPE == 1)
    wire simple_mode = (REG_TYPE == 1);
    // Skid buffer mode (REG_TYPE == 2)
    wire skid_mode = (REG_TYPE == 2);

    // For wire mode, pass through directly
    wire [DATA_WIDTH-1:0]  wire_tdata = s_axis_tdata;
    wire [KEEP_WIDTH-1:0]  wire_tkeep = s_axis_tkeep;
    wire                   wire_tvalid = s_axis_tvalid;
    wire                   wire_tlast = s_axis_tlast;
    wire [ID_WIDTH-1:0]    wire_tid = s_axis_tid;
    wire [DEST_WIDTH-1:0]  wire_tdest = s_axis_tdest;
    wire [USER_WIDTH-1:0]  wire_tuser = s_axis_tuser;
    wire                   wire_tready = m_axis_tready;

    // Simple buffer: single register stage
    reg [DATA_WIDTH-1:0]  simple_tdata_r;
    reg [KEEP_WIDTH-1:0]  simple_tkeep_r;
    reg                   simple_tvalid_r;
    reg                   simple_tlast_r;
    reg [ID_WIDTH-1:0]    simple_tid_r;
    reg [DEST_WIDTH-1:0]  simple_tdest_r;
    reg [USER_WIDTH-1:0]  simple_tuser_r;

    wire simple_tready = simple_tvalid_r ? m_axis_tready : 1'b1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            simple_tdata_r  <= {DATA_WIDTH{1'b0}};
            simple_tkeep_r  <= {KEEP_WIDTH{1'b0}};
            simple_tvalid_r <= 1'b0;
            simple_tlast_r  <= 1'b0;
            simple_tid_r    <= {ID_WIDTH{1'b0}};
            simple_tdest_r  <= {DEST_WIDTH{1'b0}};
            simple_tuser_r  <= {USER_WIDTH{1'b0}};
        end else begin
            if (s_axis_tvalid && simple_tready) begin
                simple_tdata_r  <= s_axis_tdata;
                simple_tkeep_r  <= s_axis_tkeep;
                simple_tvalid_r <= 1'b1;
                simple_tlast_r  <= s_axis_tlast;
                simple_tid_r    <= s_axis_tid;
                simple_tdest_r  <= s_axis_tdest;
                simple_tuser_r  <= s_axis_tuser;
            end else if (simple_tvalid_r && m_axis_tready) begin
                simple_tvalid_r <= 1'b0;
            end
        end
    end

    // Skid buffer: two-stage buffer to prevent dropping beats
    // Stage 1: main register
    // Stage 2: skid register
    reg [DATA_WIDTH-1:0]  skid_main_tdata_r;
    reg [KEEP_WIDTH-1:0]  skid_main_tkeep_r;
    reg                   skid_main_tvalid_r;
    reg                   skid_main_tlast_r;
    reg [ID_WIDTH-1:0]    skid_main_tid_r;
    reg [DEST_WIDTH-1:0]  skid_main_tdest_r;
    reg [USER_WIDTH-1:0]  skid_main_tuser_r;

    reg [DATA_WIDTH-1:0]  skid_skid_tdata_r;
    reg [KEEP_WIDTH-1:0]  skid_skid_tkeep_r;
    reg                   skid_skid_tvalid_r;
    reg                   skid_skid_tlast_r;
    reg [ID_WIDTH-1:0]    skid_skid_tid_r;
    reg [DEST_WIDTH-1:0]  skid_skid_tdest_r;
    reg [USER_WIDTH-1:0]  skid_skid_tuser_r;

    // Output from skid buffer
    wire [DATA_WIDTH-1:0]  skid_out_tdata;
    wire [KEEP_WIDTH-1:0]  skid_out_tkeep;
    wire                   skid_out_tvalid;
    wire                   skid_out_tlast;
    wire [ID_WIDTH-1:0]    skid_out_tid;
    wire [DEST_WIDTH-1:0]  skid_out_tdest;
    wire [USER_WIDTH-1:0]  skid_out_tuser;

    // If main is valid, output from main; else if skid is valid, output from skid
    assign skid_out_tdata  = skid_main_tvalid_r ? skid_main_tdata_r  : skid_skid_tdata_r;
    assign skid_out_tkeep  = skid_main_tvalid_r ? skid_main_tkeep_r  : skid_skid_tkeep_r;
    assign skid_out_tvalid = skid_main_tvalid_r | skid_skid_tvalid_r;
    assign skid_out_tlast  = skid_main_tvalid_r ? skid_main_tlast_r  : skid_skid_tlast_r;
    assign skid_out_tid    = skid_main_tvalid_r ? skid_main_tid_r    : skid_skid_tid_r;
    assign skid_out_tdest  = skid_main_tvalid_r ? skid_main_tdest_r  : skid_skid_tdest_r;
    assign skid_out_tuser  = skid_main_tvalid_r ? skid_main_tuser_r  : skid_skid_tuser_r;

    // Ready logic for skid buffer
    // Main can accept if: main is not valid, or main is valid and output is ready
    // Skid can accept if: skid is not valid
    // Input ready: if main is not valid, or (main is valid and output is ready)
    wire skid_main_can_accept = ~skid_main_tvalid_r | (skid_main_tvalid_r && m_axis_tready);
    wire skid_skid_can_accept = ~skid_skid_tvalid_r;
    wire skid_tready = skid_main_can_accept;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            skid_main_tdata_r  <= {DATA_WIDTH{1'b0}};
            skid_main_tkeep_r  <= {KEEP_WIDTH{1'b0}};
            skid_main_tvalid_r <= 1'b0;
            skid_main_tlast_r  <= 1'b0;
            skid_main_tid_r    <= {ID_WIDTH{1'b0}};
            skid_main_tdest_r  <= {DEST_WIDTH{1'b0}};
            skid_main_tuser_r  <= {USER_WIDTH{1'b0}};

            skid_skid_tdata_r  <= {DATA_WIDTH{1'b0}};
            skid_skid_tkeep_r  <= {KEEP_WIDTH{1'b0}};
            skid_skid_tvalid_r <= 1'b0;
            skid_skid_tlast_r  <= 1'b0;
            skid_skid_tid_r    <= {ID_WIDTH{1'b0}};
            skid_skid_tdest_r  <= {DEST_WIDTH{1'b0}};
            skid_skid_tuser_r  <= {USER_WIDTH{1'b0}};
        end else begin
            // Handle main register
            if (s_axis_tvalid && skid_tready) begin
                // New data coming in
                if (skid_main_tvalid_r) begin
                    // Main is occupied, move to skid if possible
                    if (skid_skid_can_accept) begin
                        // Move main to skid
                        skid_skid_tdata_r  <= skid_main_tdata_r;
                        skid_skid_tkeep_r  <= skid_main_tkeep_r;
                        skid_skid_tvalid_r <= 1'b1;
                        skid_skid_tlast_r  <= skid_main_tlast_r;
                        skid_skid_tid_r    <= skid_main_tid_r;
                        skid_skid_tdest_r  <= skid_main_tdest_r;
                        skid_skid_tuser_r  <= skid_main_tuser_r;
                    end
                    // Load new data into main
                    skid_main_tdata_r  <= s_axis_tdata;
                    skid_main_tkeep_r  <= s_axis_tkeep;
                    skid_main_tvalid_r <= 1'b1;
                    skid_main_tlast_r  <= s_axis_tlast;
                    skid_main_tid_r    <= s_axis_tid;
                    skid_main_tdest_r  <= s_axis_tdest;
                    skid_main_tuser_r  <= s_axis_tuser;
                end else begin
                    // Main is empty, load new data
                    skid_main_tdata_r  <= s_axis_tdata;
                    skid_main_tkeep_r  <= s_axis_tkeep;
                    skid_main_tvalid_r <= 1'b1;
                    skid_main_tlast_r  <= s_axis_tlast;
                    skid_main_tid_r    <= s_axis_tid;
                    skid_main_tdest_r  <= s_axis_tdest;
                    skid_main_tuser_r  <= s_axis_tuser;
                end
            end else if (skid_main_tvalid_r && m_axis_tready) begin
                // Main is being consumed
                if (skid_skid_tvalid_r) begin
                    // Move skid to main
                    skid_main_tdata_r  <= skid_skid_tdata_r;
                    skid_main_tkeep_r  <= skid_skid_tkeep_r;
                    skid_main_tvalid_r <= 1'b1;
                    skid_main_tlast_r  <= skid_skid_tlast_r;
                    skid_main_tid_r    <= skid_skid_tid_r;
                    skid_main_tdest_r  <= skid_skid_tdest_r;
                    skid_main_tuser_r  <= skid_skid_tuser_r;
                    skid_skid_tvalid_r <= 1'b0;
                end else begin
                    // No skid data, clear main
                    skid_main_tvalid_r <= 1'b0;
                end
            end
        end
    end

    // Mux outputs based on REG_TYPE
    assign m_axis_tdata  = wire_mode ? wire_tdata  : (simple_mode ? simple_tdata_r  : skid_out_tdata);
    assign m_axis_tkeep  = wire_mode ? wire_tkeep  : (simple_mode ? simple_tkeep_r  : skid_out_tkeep);
    assign m_axis_tvalid = wire_mode ? wire_tvalid : (simple_mode ? simple_tvalid_r : skid_out_tvalid);
    assign m_axis_tlast  = wire_mode ? wire_tlast  : (simple_mode ? simple_tlast_r  : skid_out_tlast);
    assign m_axis_tid    = wire_mode ? wire_tid    : (simple_mode ? simple_tid_r    : skid_out_tid);
    assign m_axis_tdest  = wire_mode ? wire_tdest  : (simple_mode ? simple_tdest_r  : skid_out_tdest);
    assign m_axis_tuser  = wire_mode ? wire_tuser  : (simple_mode ? simple_tuser_r  : skid_out_tuser);

    assign s_axis_tready = wire_mode ? wire_tready : (simple_mode ? simple_tready   : skid_tready);

endmodule
