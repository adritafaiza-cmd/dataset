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

    // For REG_TYPE = 0: wire (no buffering)
    // For REG_TYPE = 1: buffer (single register)
    // For REG_TYPE = 2: skid buffer (double buffer)

    // Wire mode: direct passthrough
    wire wire_tdata = s_axis_tdata;
    wire [KEEP_WIDTH-1:0] wire_tkeep = s_axis_tkeep;
    wire wire_tvalid = s_axis_tvalid;
    wire wire_tlast = s_axis_tlast;
    wire [ID_WIDTH-1:0] wire_tid = s_axis_tid;
    wire [DEST_WIDTH-1:0] wire_tdest = s_axis_tdest;
    wire [USER_WIDTH-1:0] wire_tuser = s_axis_tuser;

    // Buffer mode: single register
    // The register holds data when m_axis_tready is low
    // s_axis_tready is high when the register is empty or when m_axis_tready is high (can accept new data)

    // Skid buffer mode: two registers
    // First register (main) and second register (skid)
    // s_axis_tready is high when main is empty, or when main is full but skid is empty, or when both are full but m_axis_tready is high

    // Let's implement using a state machine approach for the skid buffer
    // State 0: both empty
    // State 1: main full, skid empty
    // State 2: main full, skid full

    reg [1:0] skid_state;

    // For buffer mode, we use a simple register
    reg buf_tdata_reg;
    reg [KEEP_WIDTH-1:0] buf_tkeep_reg;
    reg buf_tvalid_reg;
    reg buf_tlast_reg;
    reg [ID_WIDTH-1:0] buf_tid_reg;
    reg [DEST_WIDTH-1:0] buf_tdest_reg;
    reg [USER_WIDTH-1:0] buf_tuser_reg;

    // Buffer mode logic
    wire buf_can_accept = !buf_tvalid_reg || m_axis_tready;
    wire buf_can_output = buf_tvalid_reg;

    // Skid buffer logic
    // State encoding:
    // 00: both empty
    // 01: main full, skid empty
    // 10: main full, skid full
    // 11: unused

    wire skid_can_accept = (skid_state == 2'b00) || (skid_state == 2'b01) || (skid_state == 2'b10 && m_axis_tready);
    wire skid_can_output = (skid_state == 2'b01) || (skid_state == 2'b10);

    // Determine which mode to use
    // REG_TYPE = 0: wire
    // REG_TYPE = 1: buffer
    // REG_TYPE = 2: skid buffer

    // Output selection
    assign m_axis_tdata = (REG_TYPE == 0) ? wire_tdata :
                          (REG_TYPE == 1) ? buf_tdata_reg :
                          (skid_state == 2'b01 || skid_state == 2'b10) ? reg_tdata :
                          {DATA_WIDTH{1'b0}};

    assign m_axis_tkeep = (REG_TYPE == 0) ? wire_tkeep :
                          (REG_TYPE == 1) ? buf_tkeep_reg :
                          (skid_state == 2'b01 || skid_state == 2'b10) ? reg_tkeep :
                          {KEEP_WIDTH{1'b0}};

    assign m_axis_tvalid = (REG_TYPE == 0) ? wire_tvalid :
                           (REG_TYPE == 1) ? buf_tvalid_reg :
                           (skid_state == 2'b01 || skid_state == 2'b10);

    assign m_axis_tlast = (REG_TYPE == 0) ? wire_tlast :
                          (REG_TYPE == 1) ? buf_tlast_reg :
                          (skid_state == 2'b01 || skid_state == 2'b10) ? reg_tlast :
                          1'b0;

    assign m_axis_tid = (REG_TYPE == 0) ? wire_tid :
                        (REG_TYPE == 1) ? buf_tid_reg :
                        (skid_state == 2'b01 || skid_state == 2'b10) ? reg_tid :
                        {ID_WIDTH{1'b0}};

    assign m_axis_tdest = (REG_TYPE == 0) ? wire_tdest :
                          (REG_TYPE == 1) ? buf_tdest_reg :
                          (skid_state == 2'b01 || skid_state == 2'b10) ? reg_tdest :
                          {DEST_WIDTH{1'b0}};

    assign m_axis_tuser = (REG_TYPE == 0) ? wire_tuser :
                          (REG_TYPE == 1) ? buf_tuser_reg :
                          (skid_state == 2'b01 || skid_state == 2'b10) ? reg_tuser :
                          {USER_WIDTH{1'b0}};

    // Input ready
    assign s_axis_tready = (REG_TYPE == 0) ? m_axis_tready :
                           (REG_TYPE == 1) ? buf_can_accept :
                           skid_can_accept;

    // Buffer mode register logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_tdata_reg <= {DATA_WIDTH{1'b0}};
            buf_tkeep_reg <= {KEEP_WIDTH{1'b0}};
            buf_tvalid_reg <= 1'b0;
            buf_tlast_reg <= 1'b0;
            buf_tid_reg <= {ID_WIDTH{1'b0}};
            buf_tdest_reg <= {DEST_WIDTH{1'b0}};
            buf_tuser_reg <= {USER_WIDTH{1'b0}};
        end else if (REG_TYPE == 1) begin
            if (buf_can_accept && s_axis_tvalid) begin
                buf_tdata_reg <= s_axis_tdata;
                buf_tkeep_reg <= s_axis_tkeep;
                buf_tvalid_reg <= 1'b1;
                buf_tlast_reg <= s_axis_tlast;
                buf_tid_reg <= s_axis_tid;
                buf_tdest_reg <= s_axis_tdest;
                buf_tuser_reg <= s_axis_tuser;
            end else if (buf_tvalid_reg && m_axis_tready) begin
                buf_tvalid_reg <= 1'b0;
            end
        end
    end

    // Skid buffer register logic
    // reg_tdata, reg_tkeep, etc. are the main register
    // skid_tdata, skid_tkeep, etc. are the skid register

    // We need to define reg_tdata etc. as registers
    // Let's use separate register names to avoid confusion

    reg [DATA_WIDTH-1:0]  main_tdata;
    reg [KEEP_WIDTH-1:0]  main_tkeep;
    reg                   main_tvalid;
    reg                   main_tlast;
    reg [ID_WIDTH-1:0]    main_tid;
    reg [DEST_WIDTH-1:0]  main_tdest;
    reg [USER_WIDTH-1:0]  main_tuser;

    // Update the output assignments to use main_ registers
    // We need to fix the output assignments

    // Let me redo this more carefully

    // For skid buffer, the main register is what's presented to m_axis
    // The skid register holds the next data

    // State transitions:
    // State 00 (both empty):
    //   - If s_axis_tvalid: load main, go to state 01
    //   - Else: stay in state 00
    //
    // State 01 (main full, skid empty):
    //   - If m_axis_tready: main is consumed
    //     - If s_axis_tvalid: load main with new data, stay in state 01
    //     - Else: go to state 00
    //   - If !m_axis_tready and s_axis_tvalid: load skid, go to state 10
    //   - If !m_axis_tready and !s_axis_tvalid: stay in state 01
    //
    // State 10 (main full, skid full):
    //   - If m_axis_tready: main is consumed, move skid to main, go to state 01
    //   - Else: stay in state 10

    // Let's implement this properly

    // First, let's define the main register outputs
    // We'll use a separate always block for the skid buffer

    // Actually, let me restructure the entire module to be cleaner

    // I'll use a case statement for REG_TYPE

    // Let me rewrite the module

endmodule
