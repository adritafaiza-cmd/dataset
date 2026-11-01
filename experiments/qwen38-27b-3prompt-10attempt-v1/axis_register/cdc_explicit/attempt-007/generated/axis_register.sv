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

    // For wire mode, pass through directly
    wire [DATA_WIDTH-1:0]  wire_tdata;
    wire [KEEP_WIDTH-1:0]  wire_tkeep;
    wire                   wire_tvalid;
    wire                   wire_tlast;
    wire [ID_WIDTH-1:0]    wire_tid;
    wire [DEST_WIDTH-1:0]  wire_tdest;
    wire [USER_WIDTH-1:0]  wire_tuser;
    wire                   wire_tready;

    assign wire_tdata  = s_axis_tdata;
    assign wire_tkeep  = s_axis_tkeep;
    assign wire_tvalid = s_axis_tvalid;
    assign wire_tlast  = s_axis_tlast;
    assign wire_tid    = s_axis_tid;
    assign wire_tdest  = s_axis_tdest;
    assign wire_tuser  = s_axis_tuser;
    assign wire_tready = m_axis_tready;

    // For simple buffer mode
    wire [DATA_WIDTH-1:0]  simple_tdata;
    wire [KEEP_WIDTH-1:0]  simple_tkeep;
    wire                   simple_tvalid;
    wire                   simple_tlast;
    wire [ID_WIDTH-1:0]    simple_tid;
    wire [DEST_WIDTH-1:0]  simple_tdest;
    wire [USER_WIDTH-1:0]  simple_tuser;
    wire                   simple_tready;

    // For skid buffer mode
    wire [DATA_WIDTH-1:0]  skid_tdata;
    wire [KEEP_WIDTH-1:0]  skid_tkeep;
    wire                   skid_tvalid;
    wire                   skid_tlast;
    wire [ID_WIDTH-1:0]    skid_tid;
    wire [DEST_WIDTH-1:0]  skid_tdest;
    wire [USER_WIDTH-1:0]  skid_tuser;
    wire                   skid_tready;

    // Simple buffer implementation
    reg [DATA_WIDTH-1:0]  simple_data_reg;
    reg [KEEP_WIDTH-1:0]  simple_keep_reg;
    reg                   simple_valid_reg;
    reg                   simple_last_reg;
    reg [ID_WIDTH-1:0]    simple_id_reg;
    reg [DEST_WIDTH-1:0]  simple_dest_reg;
    reg [USER_WIDTH-1:0]  simple_user_reg;

    wire simple_accept = s_axis_tvalid & simple_tready;
    wire simple_output = simple_valid_reg & m_axis_tready;

    assign simple_tdata  = simple_data_reg;
    assign simple_tkeep  = simple_keep_reg;
    assign simple_tvalid = simple_valid_reg;
    assign simple_tlast  = simple_last_reg;
    assign simple_tid    = simple_id_reg;
    assign simple_tdest  = simple_dest_reg;
    assign simple_tuser  = simple_user_reg;
    assign simple_tready = !simple_valid_reg | m_axis_tready;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            simple_valid_reg <= 1'b0;
            simple_data_reg  <= {DATA_WIDTH{1'b0}};
            simple_keep_reg  <= {KEEP_WIDTH{1'b0}};
            simple_last_reg  <= 1'b0;
            simple_id_reg    <= {ID_WIDTH{1'b0}};
            simple_dest_reg  <= {DEST_WIDTH{1'b0}};
            simple_user_reg  <= {USER_WIDTH{1'b0}};
        end else begin
            if (simple_accept) begin
                simple_valid_reg <= 1'b1;
                simple_data_reg  <= s_axis_tdata;
                simple_keep_reg  <= s_axis_tkeep;
                simple_last_reg  <= s_axis_tlast;
                simple_id_reg    <= s_axis_tid;
                simple_dest_reg  <= s_axis_tdest;
                simple_user_reg  <= s_axis_tuser;
            end
            if (simple_output) begin
                simple_valid_reg <= 1'b0;
            end
            if (simple_accept && simple_output) begin
                // Both accept and output in same cycle: new data goes in, old data goes out
                // This is handled by the above assignments
            end
        end
    end

    // Skid buffer implementation
    // State: 0 = empty, 1 = main full, 2 = main and skid full
    reg [1:0] skid_state;
    reg [DATA_WIDTH-1:0]  skid_main_data;
    reg [KEEP_WIDTH-1:0]  skid_main_keep;
    reg                   skid_main_last;
    reg [ID_WIDTH-1:0]    skid_main_id;
    reg [DEST_WIDTH-1:0]  skid_main_dest;
    reg [USER_WIDTH-1:0]  skid_main_user;
    reg [DATA_WIDTH-1:0]  skid_skid_data;
    reg [KEEP_WIDTH-1:0]  skid_skid_keep;
    reg                   skid_skid_last;
    reg [ID_WIDTH-1:0]    skid_skid_id;
    reg [DEST_WIDTH-1:0]  skid_skid_dest;
    reg [USER_WIDTH-1:0]  skid_skid_user;

    wire skid_main_valid = (skid_state != 2'b00);
    wire skid_skid_valid = (skid_state == 2'b10);
    wire skid_output     = skid_main_valid & m_axis_tready;
    wire skid_accept     = s_axis_tvalid & skid_tready;

    assign skid_tdata  = skid_main_data;
    assign skid_tkeep  = skid_main_keep;
    assign skid_tvalid = skid_main_valid;
    assign skid_tlast  = skid_main_last;
    assign skid_tid    = skid_main_id;
    assign skid_tdest  = skid_main_dest;
    assign skid_tuser  = skid_main_user;

    // Skid buffer ready logic
    // Can accept if:
    // - State is empty (00): accept
    // - State is main full (01): accept only if output is happening (to move main to skid)
    // - State is full (10): cannot accept
    assign skid_tready = (skid_state == 2'b00) | (skid_state == 2'b01 & m_axis_tready);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            skid_state       <= 2'b00;
            skid_main_data   <= {DATA_WIDTH{1'b0}};
            skid_main_keep   <= {KEEP_WIDTH{1'b0}};
            skid_main_last   <= 1'b0;
            skid_main_id     <= {ID_WIDTH{1'b0}};
            skid_main_dest   <= {DEST_WIDTH{1'b0}};
            skid_main_user   <= {USER_WIDTH{1'b0}};
            skid_skid_data   <= {DATA_WIDTH{1'b0}};
            skid_skid_keep   <= {KEEP_WIDTH{1'b0}};
            skid_skid_last   <= 1'b0;
            skid_skid_id     <= {ID_WIDTH{1'b0}};
            skid_skid_dest   <= {DEST_WIDTH{1'b0}};
            skid_skid_user   <= {USER_WIDTH{1'b0}};
        end else begin
            case (skid_state)
                2'b00: begin
                    // Empty
                    if (skid_accept) begin
                        skid_state       <= 2'b01;
                        skid_main_data   <= s_axis_tdata;
                        skid_main_keep   <= s_axis_tkeep;
                        skid_main_last   <= s_axis_tlast;
                        skid_main_id     <= s_axis_tid;
                        skid_main_dest   <= s_axis_tdest;
                        skid_main_user   <= s_axis_tuser;
                    end
                end
                2'b01: begin
                    // Main full, skid empty
                    if (skid_output) begin
                        if (skid_accept) begin
                            // Move main to skid, new data to main
                            skid_state       <= 2'b01;
                            skid_skid_data   <= skid_main_data;
                            skid_skid_keep   <= skid_main_keep;
                            skid_skid_last   <= skid_main_last;
                            skid_skid_id     <= skid_main_id;
                            skid_skid_dest   <= skid_main_dest;
                            skid_skid_user   <= skid_main_user;
                            skid_main_data   <= s_axis_tdata;
                            skid_main_keep   <= s_axis_tkeep;
                            skid_main_last   <= s_axis_tlast;
                            skid_main_id     <= s_axis_tid;
                            skid_main_dest   <= s_axis_tdest;
                            skid_main_user   <= s_axis_tuser;
                        end else begin
                            // Just output main
                            skid_state       <= 2'b00;
                        end
                    end else if (skid_accept) begin
                        // No output, but accept: move main to skid, new data to main
                        skid_state       <= 2'b10;
                        skid_skid_data   <= skid_main_data;
                        skid_skid_keep   <= skid_main_keep;
                        skid_skid_last   <= skid_main_last;
                        skid_skid_id     <= skid_main_id;
                        skid_skid_dest   <= skid_main_dest;
                        skid_skid_user   <= skid_main_user;
                        skid_main_data   <= s_axis_tdata;
                        skid_main_keep   <= s_axis_tkeep;
                        skid_main_last   <= s_axis_tlast;
                        skid_main_id     <= s_axis_tid;
                        skid_main_dest   <= s_axis_tdest;
                        skid_main_user   <= s_axis_tuser;
                    end
                end
                2'b10: begin
                    // Both full
                    if (skid_output) begin
                        // Move skid to main
                        skid_state       <= 2'b01;
                        skid_main_data   <= skid_skid_data;
                        skid_main_keep   <= skid_skid_keep;
                        skid_main_last   <= skid_skid_last;
                        skid_main_id     <= skid_skid_id;
                        skid_main_dest   <= skid_skid_dest;
                        skid_main_user   <= skid_skid_user;
                    end
                end
                default: begin
                    skid_state <= 2'b00;
                end
            endcase
        end
    end

    // Mux based on REG_TYPE
    assign m_axis_tdata  = wire_mode ? wire_tdata  : (simple_mode ? simple_tdata  : skid_tdata);
    assign m_axis_tkeep  = wire_mode ? wire_tkeep  : (simple_mode ? simple_tkeep  : skid_tkeep);
    assign m_axis_tvalid = wire_mode ? wire_tvalid : (simple_mode ? simple_tvalid : skid_tvalid);
    assign m_axis_tlast  = wire_mode ? wire_tlast  : (simple_mode ? simple_tlast  : skid_tlast);
    assign m_axis_tid    = wire_mode ? wire_tid    : (simple_mode ? simple_tid    : skid_tid);
    assign m_axis_tdest  = wire_mode ? wire_tdest  : (simple_mode ? simple_tdest  : skid_tdest);
    assign m_axis_tuser  = wire_mode ? wire_tuser  : (simple_mode ? simple_tuser  : skid_tuser);

    assign s_axis_tready = wire_mode ? wire_tready : (simple_mode ? simple_tready : skid_tready);

endmodule
