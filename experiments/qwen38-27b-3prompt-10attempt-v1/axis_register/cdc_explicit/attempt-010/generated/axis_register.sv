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

    // Wire mode (REG_TYPE == 0)
    wire wire_mode = (REG_TYPE == 0);
    // Simple buffer mode (REG_TYPE == 1)
    wire simple_mode = (REG_TYPE == 1);
    // Skid buffer mode (REG_TYPE == 2)
    wire skid_mode = (REG_TYPE == 2);

    // For wire mode, just pass through
    wire wire_s_axis_tready;
    wire wire_m_axis_tdata;
    wire wire_m_axis_tkeep;
    wire wire_m_axis_tvalid;
    wire wire_m_axis_tlast;
    wire wire_m_axis_tid;
    wire wire_m_axis_tdest;
    wire wire_m_axis_tuser;

    assign wire_s_axis_tready = m_axis_tready;
    assign wire_m_axis_tdata = s_axis_tdata;
    assign wire_m_axis_tkeep = s_axis_tkeep;
    assign wire_m_axis_tvalid = s_axis_tvalid;
    assign wire_m_axis_tlast = s_axis_tlast;
    assign wire_m_axis_tid = s_axis_tid;
    assign wire_m_axis_tdest = s_axis_tdest;
    assign wire_m_axis_tuser = s_axis_tuser;

    // For simple buffer mode
    wire simple_s_axis_tready;
    wire simple_m_axis_tdata;
    wire simple_m_axis_tkeep;
    wire simple_m_axis_tvalid;
    wire simple_m_axis_tlast;
    wire simple_m_axis_tid;
    wire simple_m_axis_tdest;
    wire simple_m_axis_tuser;

    // For skid buffer mode
    wire skid_s_axis_tready;
    wire skid_m_axis_tdata;
    wire skid_m_axis_tkeep;
    wire skid_m_axis_tvalid;
    wire skid_m_axis_tlast;
    wire skid_m_axis_tid;
    wire skid_m_axis_tdest;
    wire skid_m_axis_tuser;

    // Simple buffer implementation
    reg [DATA_WIDTH-1:0]  simple_tdata_reg;
    reg [KEEP_WIDTH-1:0]  simple_tkeep_reg;
    reg                   simple_tvalid_reg;
    reg                   simple_tlast_reg;
    reg [ID_WIDTH-1:0]    simple_tid_reg;
    reg [DEST_WIDTH-1:0]  simple_tdest_reg;
    reg [USER_WIDTH-1:0]  simple_tuser_reg;

    wire simple_accept = s_axis_tvalid & simple_s_axis_tready;
    wire simple_output = simple_tvalid_reg & m_axis_tready;

    assign simple_s_axis_tready = !simple_tvalid_reg | m_axis_tready;
    assign simple_m_axis_tdata = simple_tdata_reg;
    assign simple_m_axis_tkeep = simple_tkeep_reg;
    assign simple_m_axis_tvalid = simple_tvalid_reg;
    assign simple_m_axis_tlast = simple_tlast_reg;
    assign simple_m_axis_tid = simple_tid_reg;
    assign simple_m_axis_tdest = simple_tdest_reg;
    assign simple_m_axis_tuser = simple_tuser_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            simple_tdata_reg <= {DATA_WIDTH{1'b0}};
            simple_tkeep_reg <= {KEEP_WIDTH{1'b0}};
            simple_tvalid_reg <= 1'b0;
            simple_tlast_reg <= 1'b0;
            simple_tid_reg <= {ID_WIDTH{1'b0}};
            simple_tdest_reg <= {DEST_WIDTH{1'b0}};
            simple_tuser_reg <= {USER_WIDTH{1'b0}};
        end else begin
            if (simple_accept) begin
                simple_tdata_reg <= s_axis_tdata;
                simple_tkeep_reg <= s_axis_tkeep;
                simple_tvalid_reg <= 1'b1;
                simple_tlast_reg <= s_axis_tlast;
                simple_tid_reg <= s_axis_tid;
                simple_tdest_reg <= s_axis_tdest;
                simple_tuser_reg <= s_axis_tuser;
            end
            if (simple_output) begin
                simple_tvalid_reg <= 1'b0;
            end
            if (simple_accept && simple_output) begin
                // Both happen in same cycle, so valid stays 1
                simple_tvalid_reg <= 1'b1;
            end
        end
    end

    // Skid buffer implementation
    // Main register
    reg [DATA_WIDTH-1:0]  skid_main_tdata;
    reg [KEEP_WIDTH-1:0]  skid_main_tkeep;
    reg                   skid_main_tvalid;
    reg                   skid_main_tlast;
    reg [ID_WIDTH-1:0]    skid_main_tid;
    reg [DEST_WIDTH-1:0]  skid_main_tdest;
    reg [USER_WIDTH-1:0]  skid_main_tuser;

    // Skid register
    reg [DATA_WIDTH-1:0]  skid_skid_tdata;
    reg [KEEP_WIDTH-1:0]  skid_skid_tkeep;
    reg                   skid_skid_tvalid;
    reg                   skid_skid_tlast;
    reg [ID_WIDTH-1:0]    skid_skid_tid;
    reg [DEST_WIDTH-1:0]  skid_skid_tdest;
    reg [USER_WIDTH-1:0]  skid_skid_tuser;

    wire skid_main_accept = s_axis_tvalid & skid_s_axis_tready;
    wire skid_main_output = skid_main_tvalid & m_axis_tready;
    wire skid_skid_output = skid_skid_tvalid & m_axis_tready;

    // s_axis_tready is high when we can accept new data
    // We can accept if main is empty, or if main can output this cycle
    assign skid_s_axis_tready = !skid_main_tvalid | m_axis_tready;

    // Output from main if valid, else from skid
    assign skid_m_axis_tdata = skid_main_tvalid ? skid_main_tdata : skid_skid_tdata;
    assign skid_m_axis_tkeep = skid_main_tvalid ? skid_main_tkeep : skid_skid_tkeep;
    assign skid_m_axis_tvalid = skid_main_tvalid | skid_skid_tvalid;
    assign skid_m_axis_tlast = skid_main_tvalid ? skid_main_tlast : skid_skid_tlast;
    assign skid_m_axis_tid = skid_main_tvalid ? skid_main_tid : skid_skid_tid;
    assign skid_m_axis_tdest = skid_main_tvalid ? skid_main_tdest : skid_skid_tdest;
    assign skid_m_axis_tuser = skid_main_tvalid ? skid_main_tuser : skid_skid_tuser;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            skid_main_tdata <= {DATA_WIDTH{1'b0}};
            skid_main_tkeep <= {KEEP_WIDTH{1'b0}};
            skid_main_tvalid <= 1'b0;
            skid_main_tlast <= 1'b0;
            skid_main_tid <= {ID_WIDTH{1'b0}};
            skid_main_tdest <= {DEST_WIDTH{1'b0}};
            skid_main_tuser <= {USER_WIDTH{1'b0}};

            skid_skid_tdata <= {DATA_WIDTH{1'b0}};
            skid_skid_tkeep <= {KEEP_WIDTH{1'b0}};
            skid_skid_tvalid <= 1'b0;
            skid_skid_tlast <= 1'b0;
            skid_skid_tid <= {ID_WIDTH{1'b0}};
            skid_skid_tdest <= {DEST_WIDTH{1'b0}};
            skid_skid_tuser <= {USER_WIDTH{1'b0}};
        end else begin
            // Handle main register
            if (skid_main_accept) begin
                skid_main_tdata <= s_axis_tdata;
                skid_main_tkeep <= s_axis_tkeep;
                skid_main_tvalid <= 1'b1;
                skid_main_tlast <= s_axis_tlast;
                skid_main_tid <= s_axis_tid;
                skid_main_tdest <= s_axis_tdest;
                skid_main_tuser <= s_axis_tuser;
            end
            if (skid_main_output) begin
                skid_main_tvalid <= 1'b0;
            end
            if (skid_main_accept && skid_main_output) begin
                skid_main_tvalid <= 1'b1;
            end

            // Handle skid register
            // If main is full and we accept, move to skid
            if (skid_main_tvalid && skid_main_accept && !m_axis_tready) begin
                // Main is full, can't output, so new data goes to skid
                skid_skid_tdata <= s_axis_tdata;
                skid_skid_tkeep <= s_axis_tkeep;
                skid_skid_tvalid <= 1'b1;
                skid_skid_tlast <= s_axis_tlast;
                skid_skid_tid <= s_axis_tid;
                skid_skid_tdest <= s_axis_tdest;
                skid_skid_tuser <= s_axis_tuser;
            end
            // If main outputs and skid is valid, move skid to main
            if (skid_main_output && skid_skid_tvalid) begin
                skid_main_tdata <= skid_skid_tdata;
                skid_main_tkeep <= skid_skid_tkeep;
                skid_main_tvalid <= 1'b1;
                skid_main_tlast <= skid_skid_tlast;
                skid_main_tid <= skid_skid_tid;
                skid_main_tdest <= skid_skid_tdest;
                skid_main_tuser <= skid_skid_tuser;
                skid_skid_tvalid <= 1'b0;
            end
            // If skid outputs directly (main was empty)
            if (skid_skid_output && !skid_main_tvalid) begin
                skid_skid_tvalid <= 1'b0;
            end
        end
    end

    // Mux based on REG_TYPE
    assign s_axis_tready = wire_mode ? wire_s_axis_tready :
                           simple_mode ? simple_s_axis_tready :
                           skid_s_axis_tready;

    assign m_axis_tdata = wire_mode ? wire_m_axis_tdata :
                          simple_mode ? simple_m_axis_tdata :
                          skid_m_axis_tdata;

    assign m_axis_tkeep = wire_mode ? wire_m_axis_tkeep :
                          simple_mode ? simple_m_axis_tkeep :
                          skid_m_axis_tkeep;

    assign m_axis_tvalid = wire_mode ? wire_m_axis_tvalid :
                           simple_mode ? simple_m_axis_tvalid :
                           skid_m_axis_tvalid;

    assign m_axis_tlast = wire_mode ? wire_m_axis_tlast :
                          simple_mode ? simple_m_axis_tlast :
                          skid_m_axis_tlast;

    assign m_axis_tid = wire_mode ? wire_m_axis_tid :
                        simple_mode ? simple_m_axis_tid :
                        skid_m_axis_tid;

    assign m_axis_tdest = wire_mode ? wire_m_axis_tdest :
                          simple_mode ? simple_m_axis_tdest :
                          skid_m_axis_tdest;

    assign m_axis_tuser = wire_mode ? wire_m_axis_tuser :
                          simple_mode ? simple_m_axis_tuser :
                          skid_m_axis_tuser;

endmodule
