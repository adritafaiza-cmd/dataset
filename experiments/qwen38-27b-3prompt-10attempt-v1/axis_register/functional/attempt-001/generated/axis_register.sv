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
    wire s_axis_tvalid_int;
    wire s_axis_tready_int;
    wire m_axis_tvalid_int;
    wire m_axis_tready_int;

    // For REG_TYPE 0 (wire)
    wire [DATA_WIDTH-1:0] wire_tdata;
    wire [KEEP_WIDTH-1:0] wire_tkeep;
    wire wire_tlast;
    wire [ID_WIDTH-1:0] wire_tid;
    wire [DEST_WIDTH-1:0] wire_tdest;
    wire [USER_WIDTH-1:0] wire_tuser;

    // For REG_TYPE 1 (simple buffer)
    reg [DATA_WIDTH-1:0] buf_tdata;
    reg [KEEP_WIDTH-1:0] buf_tkeep;
    reg buf_tlast;
    reg [ID_WIDTH-1:0] buf_tid;
    reg [DEST_WIDTH-1:0] buf_tdest;
    reg [USER_WIDTH-1:0] buf_tuser;
    reg buf_valid;

    // For REG_TYPE 2 (skid buffer)
    reg [DATA_WIDTH-1:0] skid_tdata;
    reg [KEEP_WIDTH-1:0] skid_tkeep;
    reg skid_tlast;
    reg [ID_WIDTH-1:0] skid_tid;
    reg [DEST_WIDTH-1:0] skid_tdest;
    reg [USER_WIDTH-1:0] skid_tuser;
    reg skid_valid;

    reg [DATA_WIDTH-1:0] main_tdata;
    reg [KEEP_WIDTH-1:0] main_tkeep;
    reg main_tlast;
    reg [ID_WIDTH-1:0] main_tid;
    reg [DEST_WIDTH-1:0] main_tdest;
    reg [USER_WIDTH-1:0] main_tuser;
    reg main_valid;

    // Wire mode
    assign wire_tdata = s_axis_tdata;
    assign wire_tkeep = s_axis_tkeep;
    assign wire_tlast = s_axis_tlast;
    assign wire_tid = s_axis_tid;
    assign wire_tdest = s_axis_tdest;
    assign wire_tuser = s_axis_tuser;

    // Simple buffer mode
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_valid <= 1'b0;
            buf_tdata <= {DATA_WIDTH{1'b0}};
            buf_tkeep <= {KEEP_WIDTH{1'b0}};
            buf_tlast <= 1'b0;
            buf_tid <= {ID_WIDTH{1'b0}};
            buf_tdest <= {DEST_WIDTH{1'b0}};
            buf_tuser <= {USER_WIDTH{1'b0}};
        end else begin
            if (s_axis_tvalid && s_axis_tready_int) begin
                buf_tdata <= s_axis_tdata;
                buf_tkeep <= s_axis_tkeep;
                buf_tlast <= s_axis_tlast;
                buf_tid <= s_axis_tid;
                buf_tdest <= s_axis_tdest;
                buf_tuser <= s_axis_tuser;
                buf_valid <= 1'b1;
            end else if (m_axis_tready_int && buf_valid) begin
                buf_valid <= 1'b0;
            end
        end
    end

    // Skid buffer mode
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            main_valid <= 1'b0;
            main_tdata <= {DATA_WIDTH{1'b0}};
            main_tkeep <= {KEEP_WIDTH{1'b0}};
            main_tlast <= 1'b0;
            main_tid <= {ID_WIDTH{1'b0}};
            main_tdest <= {DEST_WIDTH{1'b0}};
            main_tuser <= {USER_WIDTH{1'b0}};
            skid_valid <= 1'b0;
            skid_tdata <= {DATA_WIDTH{1'b0}};
            skid_tkeep <= {KEEP_WIDTH{1'b0}};
            skid_tlast <= 1'b0;
            skid_tid <= {ID_WIDTH{1'b0}};
            skid_tdest <= {DEST_WIDTH{1'b0}};
            skid_tuser <= {USER_WIDTH{1'b0}};
        end else begin
            // Determine if we can accept new data
            wire can_accept = s_axis_tvalid && s_axis_tready_int;
            wire can_output = m_axis_tready_int && main_valid;

            if (can_accept && can_output) begin
                // Both input and output active: move input to main, main to output
                main_tdata <= s_axis_tdata;
                main_tkeep <= s_axis_tkeep;
                main_tlast <= s_axis_tlast;
                main_tid <= s_axis_tid;
                main_tdest <= s_axis_tdest;
                main_tuser <= s_axis_tuser;
                main_valid <= 1'b1;
            end else if (can_accept && !can_output) begin
                // Input active, output stalled: move input to main if empty, else to skid
                if (!main_valid) begin
                    main_tdata <= s_axis_tdata;
                    main_tkeep <= s_axis_tkeep;
                    main_tlast <= s_axis_tlast;
                    main_tid <= s_axis_tid;
                    main_tdest <= s_axis_tdest;
                    main_tuser <= s_axis_tuser;
                    main_valid <= 1'b1;
                end else if (!skid_valid) begin
                    skid_tdata <= s_axis_tdata;
                    skid_tkeep <= s_axis_tkeep;
                    skid_tlast <= s_axis_tlast;
                    skid_tid <= s_axis_tid;
                    skid_tdest <= s_axis_tdest;
                    skid_tuser <= s_axis_tuser;
                    skid_valid <= 1'b1;
                end
            end else if (!can_accept && can_output) begin
                // Output active, no new input: move main to output, skid to main if needed
                main_valid <= skid_valid;
                if (skid_valid) begin
                    main_tdata <= skid_tdata;
                    main_tkeep <= skid_tkeep;
                    main_tlast <= skid_tlast;
                    main_tid <= skid_tid;
                    main_tdest <= skid_tdest;
                    main_tuser <= skid_tuser;
                    skid_valid <= 1'b0;
                end
            end
            // else: no change
        end
    end

    // Generate ready signals
    generate
        if (REG_TYPE == 0) begin : gen_wire
            assign s_axis_tready = m_axis_tready;
            assign m_axis_tvalid = s_axis_tvalid;
            assign m_axis_tdata = wire_tdata;
            assign m_axis_tkeep = wire_tkeep;
            assign m_axis_tlast = wire_tlast;
            assign m_axis_tid = wire_tid;
            assign m_axis_tdest = wire_tdest;
            assign m_axis_tuser = wire_tuser;
        end
        else if (REG_TYPE == 1) begin : gen_buffer
            assign s_axis_tready = !buf_valid;
            assign m_axis_tvalid = buf_valid;
            assign m_axis_tdata = buf_tdata;
            assign m_axis_tkeep = buf_tkeep;
            assign m_axis_tlast = buf_tlast;
            assign m_axis_tid = buf_tid;
            assign m_axis_tdest = buf_tdest;
            assign m_axis_tuser = buf_tuser;
        end
        else begin : gen_skid
            // s_axis_tready: can accept if main is empty, or if main is full but skid is empty and output is ready
            // Actually, we can accept if:
            // - main is empty, OR
            // - main is full but skid is empty AND output is ready (so we can shift)
            // But in the skid buffer, we can always accept if there's space.
            // Space exists if: main is empty, OR (main is full AND skid is empty)
            // But if both are full, we can't accept.
            // However, if output is ready and main is full, we can shift main out and accept into main.
            // So s_axis_tready = !main_valid || (main_valid && !skid_valid && m_axis_tready)
            // Wait, let's think again.
            // The skid buffer can hold 2 beats.
            // We can accept a new beat if:
            // 1. main is empty (regardless of skid)
            // 2. main is full, skid is empty, and output is ready (we can shift main out, then accept into main)
            // 3. main is full, skid is empty, and output is not ready -> can't accept
            // 4. main is full, skid is full -> can't accept
            // So: s_axis_tready = !main_valid || (!skid_valid && m_axis_tready)
            assign s_axis_tready = !main_valid || (!skid_valid && m_axis_tready);
            assign m_axis_tvalid = main_valid;
            assign m_axis_tdata = main_tdata;
            assign m_axis_tkeep = main_tkeep;
            assign m_axis_tlast = main_tlast;
            assign m_axis_tid = main_tid;
            assign m_axis_tdest = main_tdest;
            assign m_axis_tuser = main_tuser;
        end
    endgenerate

endmodule
