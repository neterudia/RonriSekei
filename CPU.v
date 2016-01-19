/*----------------------------------------------------
15-12-15 Tue. 細川航汰 No.49
簡単なCPU
-----------------------------------------------------*/
`include	"CPU1_op.v"
module instruction_set_model;

 /*-----------------------------
/     各種パラメータの設定     /
-----------------------------*/
	parameter	CYCLE = 10;		//サイクルタイム
	parameter	WIDTH = 4;		//データ巾
	parameter	ADDRSIZE = 8;	//アドレス巾
	parameter	MEMSIZE = (1 << ADDRSIZE);//メモリサイズ
	parameter	FLAGBITS = 4;	//フラグの数
	
 /*-----------------------------
/     各種レジスタの定ギ       /
-----------------------------*/
	reg[WIDTH-1:0]		MEM[0:MEMSIZE-1],	//メモリ
						ir,					//命令レジスタ
						Areg, Breg;			//凡庸レジスタ
	reg[WIDTH:0]		tempreg;			//5ビット
	reg[ADDRSIZE-1:0]	PC, PCtemp;
	reg[FLAGBITS-1:0]	flagreg;
	reg					reset;
	
	
	`define	carry	flagreg[0];
	`define	parity	flagreg[1];
	`define	zero	flagreg[2];
	`define	sign	flagreg[3];
	
 /*-------------------------------------------------
/			フラグレジスタをクリアするタスク       /
-------------------------------------------------*/
	task clearflagreg;
	begin
		flagreg = 4'b0000;
	end
	endtask
		
 /*-------------------------------------------------
/				フラグ変化のタスク			       /
-------------------------------------------------*/
	task setflag;
	input	[WIDTH:0]	res;
	begin
		flagreg[0]	= res[WIDTH];
		flagreg[1]	= ~^res;
		flagreg[2]	= ~|res[WIDTH-1:0];
		flagreg[3]	= res[WIDTH-1];
	end
	endtask
		
 /*-------------------------------------------------
/					PCに飛び先セット		       /
-------------------------------------------------*/
	task setPC;
	begin
		PCtemp[3:0]	= MEM[PC];
		PC = PC + 1;
		PCtemp[7:4]	= MEM[PC];
		PC = PCtemp-1;
	end
	endtask
		
 /*-------------------------------------------------
/					メインタスク			       /
-------------------------------------------------*/
 /*-----------------------------
/   	   命令のフェッチ      /
-----------------------------*/
	task fetch;
	begin
		ir = MEM[PC];
		PC = PC + 1;
	end
	endtask
	
 /*-----------------------------
/   	命令のデコードと実行   /
-----------------------------*/
	task execute;
	begin
		case(ir)
			`MAB	:	begin
							Areg = Breg;
						end
						
			`MBA	:	begin
							Breg = Areg;
						end
						
			`MVA	:	begin
							fetch;
							Areg = ir;
						end
						
			`MVB	:	begin
							fetch;
							Breg = ir;
						end
						
			`ADD	:	begin
							tempreg = Areg + Breg;
							clearflagreg;
							setflag(tempreg);
							Areg = tempreg[WIDTH-1:0];
						end
						
			`HLT	:	begin
							$finish;
						end
			`RLC	:	begin
							clearflagreg;
							tempreg[WIDTH-1:0] = Areg;
							tempreg = tempreg << 1;
							Areg = tempreg[WIDTH-1:0];
							Areg[0] = tempreg[WIDTH];
							setflag(tempreg);
						end	
			`RRC	:	begin
							clearflagreg;
							tempreg[WIDTH-1:0] = Areg;
							tempreg[WIDTH] = tempreg[0];
							tempreg = tempreg >> 1;
							Areg = tempreg[WIDTH-1:0];
							setflag(tempreg);
						end			
			`INR	:	begin
							clearflagreg;
							tempreg[WIDTH-1:0] = Areg;
							tempreg[WIDTH]=0;
							tempreg = tempreg + 1;
							Areg = tempreg[WIDTH-1:0];
							setflag(tempreg);
						end	
			`DCR	:	begin
							clearflagreg;
							tempreg[WIDTH-1:0] = Areg;
							tempreg[WIDTH]=0;
							tempreg = tempreg - 1;
							Areg = tempreg[WIDTH-1:0];
							setflag(tempreg);
						end
			`ANA	:	begin
							clearflagreg;
							tempreg[WIDTH-1:0] = Areg;
							tempreg[WIDTH-1:0] = tempreg[WIDTH-1:0] & Breg;
							Areg = tempreg[WIDTH-1:0];
							setflag(tempreg);
						end
						
			`JMP	:	begin
							setPC;
						end
			`JZ		:	begin
							if(flagreg[2]==1'b1)
								setPC;
							else
								fetch;
						end
			`JNZ		:	begin
							if(flagreg[2]==1'b0)
								setPC;
							else
								fetch;
						end
			default	:	$display("ﾀﾞﾒ");
		endcase
	end
	endtask
 /*-------------------------------------------------
/					初期化タスク			       /
-------------------------------------------------*/
	task apply_reset;
	begin
		reset = 1;
		#CYCLE
		reset = 0;
		PC = 0;
		clearflagreg;
	end
	endtask
	
 /*-------------------------------------------------
/			initialとalwaysブロック			       /
-------------------------------------------------*/
 /*-----------------------------
/ プログラムの読み出しブロック /
-----------------------------*/
initial begin : prog_load
			$readmemb("CPU1.pro", MEM);
			apply_reset;
		end
	
 /*-----------------------------
/ 		メインプロセス 		   /
-----------------------------*/
always begin : mainprosess
			if(!reset)
				begin
					#CYCLE fetch;
					#CYCLE execute;
				end
			else	#CYCLE;
		end
		
endmodule
