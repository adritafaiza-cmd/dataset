`timescale 1ns/1ps
module apbxclk_tb;
  localparam AW=12, DW=32;
  integer errors, reqs, rsps, downstream, delay_count, age, i;
  reg sclk, mclk, rstn;
  reg s_psel, s_penable, s_pwrite;
  reg [AW-1:0] s_paddr;
  reg [DW-1:0] s_pwdata;
  reg [3:0] s_pstrb;
  wire s_pready, s_pslverr;
  wire [DW-1:0] s_prdata;
  wire m_resetn, m_psel, m_penable, m_pwrite;
  wire [AW-1:0] m_paddr;
  wire [DW-1:0] m_pwdata;
  wire [3:0] m_pstrb;
  wire [2:0] m_pprot;
  reg m_pready, m_pslverr;
  reg [DW-1:0] m_prdata;
  reg [DW-1:0] mem[0:255];
  reg prev_wait, prev_write;
  reg [AW-1:0] prev_addr;
  reg [DW-1:0] prev_data;

  always #5 sclk=~sclk;
  always #7 mclk=~mclk;
  always @* m_prdata=mem[m_paddr[9:2]];
  apbxclk #(.C_APB_ADDR_WIDTH(AW),.C_APB_DATA_WIDTH(DW),.OPT_REGISTERED(0)) dut(
    .S_APB_PCLK(sclk),.S_PRESETn(rstn),.S_APB_PSEL(s_psel),
    .S_APB_PENABLE(s_penable),.S_APB_PREADY(s_pready),.S_APB_PADDR(s_paddr),
    .S_APB_PWRITE(s_pwrite),.S_APB_PWDATA(s_pwdata),.S_APB_PWSTRB(s_pstrb),
    .S_APB_PPROT(3'b0),.S_APB_PRDATA(s_prdata),.S_APB_PSLVERR(s_pslverr),
    .M_APB_PCLK(mclk),.M_PRESETn(m_resetn),.M_APB_PSEL(m_psel),
    .M_APB_PENABLE(m_penable),.M_APB_PREADY(m_pready),.M_APB_PADDR(m_paddr),
    .M_APB_PWRITE(m_pwrite),.M_APB_PWDATA(m_pwdata),.M_APB_PWSTRB(m_pstrb),
    .M_APB_PPROT(m_pprot),.M_APB_PRDATA(m_prdata),.M_APB_PSLVERR(m_pslverr));

  always @(posedge mclk) begin
    if (!m_resetn) begin m_pready<=0; delay_count<=0; end
    else begin
      if (m_psel && m_penable && !m_pready) delay_count<=delay_count+1;
      else delay_count<=0;
      m_pready <= m_psel && m_penable && (delay_count>=2);
      if (m_psel && m_penable && m_pready) begin
        downstream=downstream+1;
        if (m_pwrite) mem[m_paddr[9:2]]<=m_pwdata;
      end
      if (prev_wait && (!m_psel || !m_penable || m_paddr!==prev_addr ||
          m_pwdata!==prev_data || m_pwrite!==prev_write)) begin
        $display("CDC/RESET VIOLATION [APB_STALL_STABILITY]: downstream payload changed while stalled");
        errors=errors+1;
      end
      if (m_psel && ((^m_paddr===1'bx)||(^m_pwrite===1'bx))) begin
        $display("CDC/RESET VIOLATION [APB_REQUEST_KNOWN]: X on active downstream request"); errors=errors+1;
      end
      prev_wait<=m_psel && m_penable && !m_pready;
      prev_addr<=m_paddr; prev_data<=m_pwdata; prev_write<=m_pwrite;
    end
  end

  always @(posedge sclk) begin
    if (!rstn) age<=0;
    else begin
      if (s_psel && !s_penable) reqs=reqs+1;
      if (s_pready) begin
        rsps=rsps+1; age<=0;
        if (rsps>reqs) begin
          $display("CDC/RESET VIOLATION [APB_RESPONSE_COHERENCY]: response without request"); errors=errors+1;
        end
        if ((^s_prdata===1'bx)||(^s_pslverr===1'bx)) begin
          $display("CDC/RESET VIOLATION [APB_RESPONSE_KNOWN]: X in response"); errors=errors+1;
        end
      end else if (s_psel && s_penable) begin
        age<=age+1;
        if (age>100) begin
          $display("CDC/RESET VIOLATION [APB_CROSS_DOMAIN_LATENCY]: bounded latency exceeded"); errors=errors+1; age<=0;
        end
      end
    end
  end

  task apb_write;
    input [AW-1:0] a; input [DW-1:0] d;
    begin
      @(negedge sclk); s_paddr=a; s_pwdata=d; s_pwrite=1; s_pstrb=4'hf;
      s_psel=1; s_penable=0;
      @(negedge sclk); s_penable=1;
      while(!s_pready) @(negedge sclk);
      @(negedge sclk); s_psel=0; s_penable=0; s_pwrite=0;
    end
  endtask
  task apb_read_check;
    input [AW-1:0] a; input [DW-1:0] e;
    begin
      @(negedge sclk); s_paddr=a; s_pwrite=0; s_psel=1; s_penable=0;
      @(negedge sclk); s_penable=1;
      while(!s_pready) @(negedge sclk);
      if(s_prdata!==e) begin $display("CDC/RESET VIOLATION [APB_DATA_COHERENCY]: read %h expected %h",s_prdata,e); errors=errors+1; end
      @(negedge sclk); s_psel=0; s_penable=0;
    end
  endtask

  initial begin
    errors=0; reqs=0; rsps=0; downstream=0; delay_count=0; age=0;
    sclk=0; mclk=0; rstn=0; s_psel=0; s_penable=0; s_pwrite=0;
    s_paddr=0; s_pwdata=0; s_pstrb=0; m_pready=0;
    m_pslverr=0; prev_wait=0;
    for(i=0;i<256;i=i+1) mem[i]=0;
    repeat(7) @(posedge sclk); rstn=1; repeat(8) @(posedge sclk);
    apb_write(12'h004,32'h11223344); apb_read_check(12'h004,32'h11223344);
    apb_write(12'h008,32'ha5a55a5a); apb_read_check(12'h008,32'ha5a55a5a);
    fork
      begin
        @(negedge sclk); s_paddr=12'h00c; s_pwdata=32'hdeadbeef;
        s_pwrite=1; s_pstrb=4'hf; s_psel=1; s_penable=0;
        @(negedge sclk); s_penable=1;
      end
      begin
        repeat(3) @(posedge mclk); rstn=0; s_psel=0; s_penable=0;
        repeat(6) @(posedge sclk); rstn=1;
      end
    join
    reqs=0; rsps=0; downstream=0; repeat(10) @(posedge sclk);
    apb_write(12'h00c,32'hcafef00d); apb_read_check(12'h00c,32'hcafef00d);
    if(reqs!=rsps || reqs!=downstream) begin
      $display("CDC/RESET VIOLATION [APB_TRANSACTION_CONSERVATION]: req=%0d rsp=%0d dst=%0d",reqs,rsps,downstream); errors=errors+1;
    end
    if(errors==0) $display("APBXCLK ENHANCED: ALL TESTS PASSED");
    else $display("APBXCLK ENHANCED: TESTS FAILED (%0d)",errors);
    $finish;
  end
  initial begin #150000; $display("APBXCLK ENHANCED: TIMEOUT"); $finish; end
endmodule
