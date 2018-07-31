set seed 23423
set background #000

set maxdepth 128
set maxobjects 32645
set minsize 0.125


{ color white } Core

rule Core
{
  SphereStuct
}

rule SphereStuct w 40 //md here is fullness of cylinder
{
	ubox
	dbox
	{ x 2 y 3.25 ry 12 } SphereStuct //this is the cylinder
}

rule SphereStuct  w 14 {  r2 }

rule r2 w 10 
{  
	{} r2
}

rule r2 {  SphereStuct }

// start hexagon sequences
//maxdepth controls fullness
rule dbox w 8 maxdepth 5
{
	{ x 0 y -6.5 rx 0  } dbox //rx here is curve of sphere
	{ ry 6 rx 0 } Panel
}
rule dbox w 8 maxdepth 3
{
	{ x 0 y -6.5 rx 0  } dbox
	{ ry 6 rx 0 } Panel
}

//rule dbox { }

rule ubox w 8 maxdepth 5
{
	{ x 0 y 6.5 rx 0  }  ubox
	{ ry 6 rx 1.8 } Panel
}
rule ubox w 8 maxdepth 3
{
	{ x 0 y 6.5 rx 0  }  ubox
	{ ry 6 rx 1.8 } Panel
}

//rule ubox { }

//end hexegon sequences

rule Panel md 1 w 1
{
	//{ y 1.0 rz -60 y 1.0  } Panel
}

rule Panel md 6 w 16 
{
	PanelPart
	{ y 1.0 rz -60 y 1.0  } Panel
}
rule PanelPart
{
	{ rz 90 s 0.2 0.2 0.1 } beamAssembly //this is the fidgets
	{ s 0.1 2.05 0.4 } box //!!! this is hexagon depth
}

// Beam

rule beamAssembly w 1
{
	{ z -5 } beam
	{ z 5 } beam

	{ s 1 0.2 11 y 12 } box
	{ s 1 0.2 11 y -12 } box

	{ z 0.4 } vertPanel
	{ z 5 } vertPanel
	{ z -5 } vertPanel
}

rule beamAssembly w 6
{
}

rule vertPanel 
{
	{s 1 4 0.2} box
	{s 1 1 0.5} box
}

rule vertPanel md 8 > end //"end of rule?" 
{
	widePane
	{ y 1 } vertPanel
}

rule end 
{
}

rule vertPanel 
{
	{s 1 1 0.5 } box
	{s 0.2 4 0.2 x 2 } box
	{s 0.2 4 0.2 x -2 } box
	{s 1 0.2 0.2 y 10 } box
	{s 1 0.2 0.2 y -10 } box
}

rule beam 
{
	{ s 0.2 5 0.2 } box
}

rule widePane 
{
	thinBeam1
	//{ y 5 } thinBeam1
	{ x 2.9 y 2.5 } thinBeamVert
	{ x -1.9 y 2.5 } thinBeamVert
	pane
}

rule widePane 
{
	//thinBeam1
	//{ y 5 } thinBeam1
	{ x 3.9 y 2.5 } thinBeamVert
	{ x -0.9 y 2.5 } thinBeamVert
	pane
}

rule widePane 
{
}

rule pane 
{
	{s 5 2.5 0.05 y 0.5} box
}

rule pane 
{
	{ s 10 2.5 0.05 y 0.5 } box
}

rule thinBeam1 
{
	{ s 10 0.2 0.2 } box
}

rule thinBeamVert 
{
	{ s 0.2 5 0.2 } box
}