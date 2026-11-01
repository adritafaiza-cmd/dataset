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

    // For REG_TYPE 0 (wire), no registers
    // For REG_TYPE 1 (simple buffer), one stage of registers
    // For REG_TYPE 2 (skid buffer), two stages with skid logic

    generate
        if (REG_TYPE == 0) begin : gen_wire
            // Wire: direct connection
            assign s_axis_tready = m_axis_tready;
            assign m_axis_tdata  = s_axis_tdata;
            assign m_axis_tkeep  = s_axis_tkeep;
            assign m_axis_tvalid = s_axis_tvalid;
            assign m_axis_tlast  = s_axis_tlast;
            assign m_axis_tid    = s_axis_tid;
            assign m_axis_tdest  = s_axis_tdest;
            assign m_axis_tuser  = s_axis_tuser;
        end
        else if (REG_TYPE == 1) begin : gen_simple_buffer
            // Simple buffer: one register stage
            // s_axis_tready is high when the register is empty or when the output is ready
            // m_axis_tvalid is high when the register is full

            reg [DATA_WIDTH-1:0]  r_tdata;
            reg [KEEP_WIDTH-1:0]  r_tkeep;
            reg                   r_tvalid;
            reg                   r_tlast;
            reg [ID_WIDTH-1:0]    r_tid;
            reg [DEST_WIDTH-1:0]  r_tdest;
            reg [USER_WIDTH-1:0]  r_tuser;

            // s_axis_tready: accept new data if register is empty or if output is consuming
            assign s_axis_tready = ~r_tvalid | m_axis_tready;

            // m_axis_tvalid: register has data
            assign m_axis_tvalid = r_tvalid;

            // Output from register
            assign m_axis_tdata  = r_tdata;
            assign m_axis_tkeep  = r_tkeep;
            assign m_axis_tlast  = r_tlast;
            assign m_axis_tid    = r_tid;
            assign m_axis_tdest  = r_tdest;
            assign m_axis_tuser  = r_tuser;

            // Register logic
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    r_tvalid <= 1'b0;
                    r_tdata  <= {DATA_WIDTH{1'b0}};
                    r_tkeep  <= {KEEP_WIDTH{1'b0}};
                    r_tlast  <= 1'b0;
                    r_tid    <= {ID_WIDTH{1'b0}};
                    r_tdest  <= {DEST_WIDTH{1'b0}};
                    r_tuser  <= {USER_WIDTH{1'b0}};
                end else begin
                    // If output is ready, clear valid (data is consumed)
                    // If input is valid and (register empty or output ready), load new data
                    if (m_axis_tready) begin
                        r_tvalid <= 1'b0;
                    end
                    if (s_axis_tvalid && s_axis_tready) begin
                        r_tvalid <= 1'b1;
                        r_tdata  <= s_axis_tdata;
                        r_tkeep  <= s_axis_tkeep;
                        r_tlast  <= s_axis_tlast;
                        r_tid    <= s_axis_tid;
                        r_tdest  <= s_axis_tdest;
                        r_tuser  <= s_axis_tuser;
                    end
                end
            end
        end
        else if (REG_TYPE == 2) begin : gen_skid_buffer
            // Skid buffer: two register stages
            // Stage 1: main register
            // Stage 2: skid register
            // The skid buffer ensures no beat is dropped when output stalls

            reg [DATA_WIDTH-1:0]  r1_tdata;
            reg [KEEP_WIDTH-1:0]  r1_tkeep;
            reg                   r1_tvalid;
            reg                   r1_tlast;
            reg [ID_WIDTH-1:0]    r1_tid;
            reg [DEST_WIDTH-1:0]  r1_tdest;
            reg [USER_WIDTH-1:0]  r1_tuser;

            reg [DATA_WIDTH-1:0]  r2_tdata;
            reg [KEEP_WIDTH-1:0]  r2_tkeep;
            reg                   r2_tvalid;
            reg                   r2_tlast;
            reg [ID_WIDTH-1:0]    r2_tid;
            reg [DEST_WIDTH-1:0]  r2_tdest;
            reg [USER_WIDTH-1:0]  r2_tuser;

            // s_axis_tready: accept new data if both registers are empty,
            // or if stage 1 is empty and stage 2 is empty,
            // or if stage 1 is full but stage 2 is empty and output is ready
            // More precisely:
            // - If r1 is empty, accept if r2 is empty or if output is ready (to move r2 to r1)
            // - If r1 is full, accept only if r2 is empty and output is ready (to move r2 to r1, then load r1)
            
            // Let's define:
            // can_accept = ~r1_tvalid | (~r2_tvalid & m_axis_tready)
            // But we also need to handle the case where r1 is full, r2 is empty, and output is ready:
            // In that case, we can move r2 to r1 (but r2 is empty, so nothing to move), and then load r1.
            // Actually, if r1 is full and r2 is empty, we can only accept if output is ready, because
            // we need to move r1 to output, and then load new data into r1.
            
            // Standard skid buffer logic:
            // s_axis_tready = ~r1_tvalid | (~r2_tvalid & m_axis_tready)
            // This means:
            // - If r1 is empty, we can always accept (r2 will be loaded if r1 was full, but r1 is empty so r2 stays)
            // - If r1 is full, we can accept only if r2 is empty and output is ready
            
            assign s_axis_tready = ~r1_tvalid | (~r2_tvalid & m_axis_tready);

            // m_axis_tvalid: output is valid if r1 is valid or r2 is valid
            // Actually, in a skid buffer, the output is driven by r1. r2 is the skid.
            // When r1 is full and output is ready, r1 is consumed and r2 is moved to r1.
            // So m_axis_tvalid should be r1_tvalid.
            
            assign m_axis_tvalid = r1_tvalid;

            // Output from stage 1
            assign m_axis_tdata  = r1_tdata;
            assign m_axis_tkeep  = r1_tkeep;
            assign m_axis_tlast  = r1_tlast;
            assign m_axis_tid    = r1_tid;
            assign m_axis_tdest  = r1_tdest;
            assign m_axis_tuser  = r1_tuser;

            // Register logic
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    r1_tvalid <= 1'b0;
                    r1_tdata  <= {DATA_WIDTH{1'b0}};
                    r1_tkeep  <= {KEEP_WIDTH{1'b0}};
                    r1_tlast  <= 1'b0;
                    r1_tid    <= {ID_WIDTH{1'b0}};
                    r1_tdest  <= {DEST_WIDTH{1'b0}};
                    r1_tuser  <= {USER_WIDTH{1'b0}};

                    r2_tvalid <= 1'b0;
                    r2_tdata  <= {DATA_WIDTH{1'b0}};
                    r2_tkeep  <= {KEEP_WIDTH{1'b0}};
                    r2_tlast  <= 1'b0;
                    r2_tid    <= {ID_WIDTH{1'b0}};
                    r2_tdest  <= {DEST_WIDTH{1'b0}};
                    r2_tuser  <= {USER_WIDTH{1'b0}};
                end else begin
                    // Determine if we are accepting new data
                    wire accept = s_axis_tvalid & s_axis_tready;
                    // Determine if output is consuming
                    wire consume = m_axis_tready & r1_tvalid;

                    // Update r2 (skid register)
                    // r2 is loaded when r1 is full and we accept new data
                    if (r1_tvalid & accept) begin
                        r2_tvalid <= 1'b1;
                        r2_tdata  <= s_axis_tdata;
                        r2_tkeep  <= s_axis_tkeep;
                        r2_tlast  <= s_axis_tlast;
                        r2_tid    <= s_axis_tid;
                        r2_tdest  <= s_axis_tdest;
                        r2_tuser  <= s_axis_tuser;
                    end else if (consume & r2_tvalid) begin
                        // Move r2 to r1, so r2 becomes empty
                        r2_tvalid <= 1'b0;
                    end

                    // Update r1 (main register)
                    if (consume) begin
                        // Output is consuming r1
                        if (r2_tvalid) begin
                            // Move r2 to r1
                            r1_tvalid <= 1'b1;
                            r1_tdata  <= r2_tdata;
                            r1_tkeep  <= r2_tkeep;
                            r1_tlast  <= r2_tlast;
                            r1_tid    <= r2_tid;
                            r1_tdest  <= r2_tdest;
                            r1_tuser  <= r2_tuser;
                        end else if (accept) begin
                            // Load new data into r1
                            r1_tvalid <= 1'b1;
                            r1_tdata  <= s_axis_tdata;
                            r1_tkeep  <= s_axis_tkeep;
                            r1_tlast  <= s_axis_tlast;
                            r1_tid    <= s_axis_tid;
                            r1_tdest  <= s_axis_tdest;
                            r1_tuser  <= s_axis_tuser;
                        end else begin
                            // r1 becomes empty
                            r1_tvalid <= 1'b0;
                        end
                    end else if (accept & ~r1_tvalid) begin
                        // r1 is empty and we accept new data
                        r1_tvalid <= 1'b1;
                        r1_tdata  <= s_axis_tdata;
                        r1_tkeep  <= s_axis_tkeep;
                        r1_tlast  <= s_axis_tlast;
                        r1_tid    <= s_axis_tid;
                        r1_tdest  <= s_axis_tdest;
                        r1_tuser  <= s_axis_tuser;
                    end
                end
            end
        end
        else begin : gen_invalid
            // Invalid REG_TYPE, treat as wire
            assign s_axis_tready = m_axis_tready;
            assign m_axis_tdata  = s_axis_tdata;
            assign m_axis_tkeep  = s_axis_tkeep;
            assign m_axis_tvalid = s_axis_tvalid;
            assign m_axis_tlast  = s_axis_tlast;
            assign m_axis_tid    = s_axis_tid;
            assign m_axis_tdest  = s_axis_tdest;
            assign m_axis_tuser  = s_axis_tuser;
        end
    endgenerate

endmodule
