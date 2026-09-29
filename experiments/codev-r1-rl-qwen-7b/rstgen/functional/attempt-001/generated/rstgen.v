module rstgen (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic test_mode_i,
    output logic rst_no,
    output logic init_no
);

    // Synchronization registers
    reg [1:0] sync;

    // Synchronized reset logic
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync <= 2'b00;
        end else begin
            sync <= {sync[0], 1'b1};
        end
    end

    // Assign synchronized reset when not in test mode
    assign rst_no = test_mode_i ? rst_ni : (sync[1] & sync[0]);

    // Init_no generation
    reg init_reg;
    reg rst_no_delayed;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            init_reg <= 1'b0;
            rst_no_delayed <= 1'b0;
        end else begin
            init_reg <= 1'b1;
            rst_no_delayed <= rst_no;
        end
    end

    wire rst_no_posedge = rst_no & ~rst_no_delayed;

    assign init_no = test_mode_i ? init_reg : rst_no_posedge;

endmodule
