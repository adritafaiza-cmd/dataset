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

    // REG_TYPE: 0 = wire, 1 = buffer, 2 = skid buffer

    // Wire mode (REG_TYPE == 0)
    wire wire_mode = (REG_TYPE == 0);
    // Buffer mode (REG_TYPE == 1)
    wire buffer_mode = (REG_TYPE == 1);
    // Skid buffer mode (REG_TYPE == 2)
    wire skid_mode = (REG_TYPE == 2);

    // Internal signals for buffer/skid buffer
    reg [DATA_WIDTH-1:0]  reg_tdata;
    reg [KEEP_WIDTH-1:0]  reg_tkeep;
    reg                   reg_tlast;
    reg [ID_WIDTH-1:0]    reg_tid;
    reg [DEST_WIDTH-1:0]  reg_tdest;
    reg [USER_WIDTH-1:0]  reg_tuser;
    reg                   reg_tvalid;

    // Skid buffer additional storage
    reg [DATA_WIDTH-1:0]  skid_tdata;
    reg [KEEP_WIDTH-1:0]  skid_tkeep;
    reg                   skid_tlast;
    reg [ID_WIDTH-1:0]    skid_tid;
    reg [DEST_WIDTH-1:0]  skid_tdest;
    reg [USER_WIDTH-1:0]  skid_tuser;
    reg                   skid_tvalid;

    // Control signals
    wire s_axis_tready_wire;
    wire s_axis_tready_buffer;
    wire s_axis_tready_skid;

    wire m_axis_tvalid_wire;
    wire m_axis_tvalid_buffer;
    wire m_axis_tvalid_skid;

    // Wire mode: direct passthrough
    assign s_axis_tready_wire = m_axis_tready;
    assign m_axis_tvalid_wire = s_axis_tvalid;

    // Buffer mode: single register
    // s_axis_tready is high when the register is empty or when the downstream is ready
    assign s_axis_tready_buffer = !reg_tvalid || m_axis_tready;
    assign m_axis_tvalid_buffer = reg_tvalid;

    // Skid buffer mode: two registers
    // s_axis_tready is high when the main register is empty, or when both are empty,
    // or when the downstream is ready and the skid is empty, etc.
    // Standard skid buffer logic:
    // - If main register is empty, accept input
    // - If main register is full but skid is empty, accept input only if downstream is ready
    // - If both are full, don't accept
    // - m_axis_tvalid is high if either register has data

    wire skid_main_empty = !reg_tvalid;
    wire skid_skid_empty = !skid_tvalid;
    wire skid_both_empty = skid_main_empty && skid_skid_empty;
    wire skid_main_full = reg_tvalid;
    wire skid_skid_full = skid_tvalid;

    // s_axis_tready for skid buffer:
    // Can accept if main is empty, or if main is full but skid is empty and downstream is ready
    assign s_axis_tready_skid = skid_main_empty || (skid_main_full && skid_skid_empty && m_axis_tready);

    // m_axis_tvalid for skid buffer:
    // Valid if main has data, or if main is empty but skid has data
    assign m_axis_tvalid_skid = reg_tvalid || skid_tvalid;

    // Select based on REG_TYPE
    assign s_axis_tready = wire_mode ? s_axis_tready_wire :
                           buffer_mode ? s_axis_tready_buffer :
                           s_axis_tready_skid;

    assign m_axis_tvalid = wire_mode ? m_axis_tvalid_wire :
                           buffer_mode ? m_axis_tvalid_buffer :
                           m_axis_tvalid_skid;

    // Output data selection
    wire [DATA_WIDTH-1:0]  out_tdata;
    wire [KEEP_WIDTH-1:0]  out_tkeep;
    wire                   out_tlast;
    wire [ID_WIDTH-1:0]    out_tid;
    wire [DEST_WIDTH-1:0]  out_tdest;
    wire [USER_WIDTH-1:0]  out_tuser;

    // For wire mode, output is directly from input
    // For buffer mode, output is from the register
    // For skid buffer mode, output is from main register if valid, else from skid

    wire skid_use_main = reg_tvalid;
    wire skid_use_skid = !reg_tvalid && skid_tvalid;

    assign out_tdata = wire_mode ? s_axis_tdata :
                       buffer_mode ? reg_tdata :
                       (skid_use_main ? reg_tdata : skid_tdata);

    assign out_tkeep = wire_mode ? s_axis_tkeep :
                       buffer_mode ? reg_tkeep :
                       (skid_use_main ? reg_tkeep : skid_tkeep);

    assign out_tlast = wire_mode ? s_axis_tlast :
                       buffer_mode ? reg_tlast :
                       (skid_use_main ? reg_tlast : skid_tlast);

    assign out_tid = wire_mode ? s_axis_tid :
                     buffer_mode ? reg_tid :
                     (skid_use_main ? reg_tid : skid_tid);

    assign out_tdest = wire_mode ? s_axis_tdest :
                       buffer_mode ? reg_tdest :
                       (skid_use_main ? reg_tdest : skid_tdest);

    assign out_tuser = wire_mode ? s_axis_tuser :
                       buffer_mode ? reg_tuser :
                       (skid_use_main ? reg_tuser : skid_tuser);

    assign m_axis_tdata = out_tdata;
    assign m_axis_tkeep = out_tkeep;
    assign m_axis_tlast = out_tlast;
    assign m_axis_tid = out_tid;
    assign m_axis_tdest = out_tdest;
    assign m_axis_tuser = out_tuser;

    // Handshake signals for register updates
    wire s_handshake = s_axis_tvalid && s_axis_tready;
    wire m_handshake = m_axis_tvalid && m_axis_tready;

    // Buffer mode register logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_tvalid <= 1'b0;
            reg_tdata <= {DATA_WIDTH{1'b0}};
            reg_tkeep <= {KEEP_WIDTH{1'b0}};
            reg_tlast <= 1'b0;
            reg_tid <= {ID_WIDTH{1'b0}};
            reg_tdest <= {DEST_WIDTH{1'b0}};
            reg_tuser <= {USER_WIDTH{1'b0}};
        end else if (buffer_mode) begin
            if (s_handshake) begin
                reg_tvalid <= 1'b1;
                reg_tdata <= s_axis_tdata;
                reg_tkeep <= s_axis_tkeep;
                reg_tlast <= s_axis_tlast;
                reg_tid <= s_axis_tid;
                reg_tdest <= s_axis_tdest;
                reg_tuser <= s_axis_tuser;
            end
            if (m_handshake) begin
                reg_tvalid <= 1'b0;
            end
            if (s_handshake && m_handshake) begin
                // Both happen: load new data, keep valid
                reg_tvalid <= 1'b1;
                reg_tdata <= s_axis_tdata;
                reg_tkeep <= s_axis_tkeep;
                reg_tlast <= s_axis_tlast;
                reg_tid <= s_axis_tid;
                reg_tdest <= s_axis_tdest;
                reg_tuser <= s_axis_tuser;
            end
        end else if (skid_mode) begin
            // Skid buffer logic
            // Priority:
            // 1. If both main and skid are empty:
            //    - If s_handshake: load main
            // 2. If main is full, skid is empty:
            //    - If m_handshake: move main to output (main becomes empty)
            //      - If s_handshake: load main with new data
            //    - If s_handshake && !m_handshake: load skid
            // 3. If main is empty, skid is full:
            //    - Move skid to main
            //    - If s_handshake: load main with new data (overwriting the moved data? No, we need to be careful)
            //    Actually, let's use a cleaner approach.

            // Let's define the transitions more carefully:
            // State: main_valid, skid_valid
            // Transitions based on s_handshake and m_handshake

            if (skid_main_empty && skid_skid_empty) begin
                // Both empty
                if (s_handshake) begin
                    reg_tvalid <= 1'b1;
                    reg_tdata <= s_axis_tdata;
                    reg_tkeep <= s_axis_tkeep;
                    reg_tlast <= s_axis_tlast;
                    reg_tid <= s_axis_tid;
                    reg_tdest <= s_axis_tdest;
                    reg_tuser <= s_axis_tuser;
                end
            end else if (skid_main_full && skid_skid_empty) begin
                // Main full, skid empty
                if (m_handshake) begin
                    // Main is being consumed
                    if (s_handshake) begin
                        // New data comes in, load into main
                        reg_tdata <= s_axis_tdata;
                        reg_tkeep <= s_axis_tkeep;
                        reg_tlast <= s_axis_tlast;
                        reg_tid <= s_axis_tid;
                        reg_tdest <= s_axis_tdest;
                        reg_tuser <= s_axis_tuser;
                        // reg_tvalid stays 1
                    end else begin
                        // No new data, main becomes empty
                        reg_tvalid <= 1'b0;
                    end
                end else if (s_handshake) begin
                    // No downstream ready, but new data comes in: load into skid
                    skid_tvalid <= 1'b1;
                    skid_tdata <= s_axis_tdata;
                    skid_tkeep <= s_axis_tkeep;
                    skid_tlast <= s_axis_tlast;
                    skid_tid <= s_axis_tid;
                    skid_tdest <= s_axis_tdest;
                    skid_tuser <= s_axis_tuser;
                end
            end else if (skid_main_empty && skid_skid_full) begin
                // Main empty, skid full
                // Move skid to main
                reg_tvalid <= 1'b1;
                reg_tdata <= skid_tdata;
                reg_tkeep <= skid_tkeep;
                reg_tlast <= skid_tlast;
                reg_tid <= skid_tid;
                reg_tdest <= skid_tdest;
                reg_tuser <= skid_tuser;
                skid_tvalid <= 1'b0;

                if (s_handshake) begin
                    // New data comes in, load into main (overwriting the just-moved data? No, we need to load into skid)
                    // Actually, if we move skid to main, and new data comes in, we should load new data into skid
                    // But we just cleared skid. So we can load new data into skid.
                    skid_tvalid <= 1'b1;
                    skid_tdata <= s_axis_tdata;
                    skid_tkeep <= s_axis_tkeep;
                    skid_tlast <= s_axis_tlast;
                    skid_tid <= s_axis_tid;
                    skid_tdest <= s_axis_tdest;
                    skid_tuser <= s_axis_tuser;
                end
            end else if (skid_main_full && skid_skid_full) begin
                // Both full
                if (m_handshake) begin
                    // Main is being consumed, move skid to main
                    reg_tdata <= skid_tdata;
                    reg_tkeep <= skid_tkeep;
                    reg_tlast <= skid_tlast;
                    reg_tid <= skid_tid;
                    reg_tdest <= skid_tdest;
                    reg_tuser <= skid_tuser;
                    skid_tvalid <= 1'b0;
                    // reg_tvalid stays 1
                end
            end
        end
    end

endmodule
