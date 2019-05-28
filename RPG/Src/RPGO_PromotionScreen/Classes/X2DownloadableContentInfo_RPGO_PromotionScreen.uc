class X2DownloadableContentInfo_RPGO_PromotionScreen extends X2DownloadableContentInfo;

exec function PSSetXoffsetBG(int AdjustXOffset)
{
	local RPGO_UIArmory_PromotionHero UI;
	
	UI = RPGO_UIArmory_PromotionHero(`SCREENSTACK.GetFirstInstanceOf(class'RPGO_UIArmory_PromotionHero'));
	UI.MC.ChildSetNum("bg", "_x", AdjustXOffset);
}

exec function PSSetWidth(int Width)
{
	local RPGO_UIArmory_PromotionHero UI;
	
	UI = RPGO_UIArmory_PromotionHero(`SCREENSTACK.GetFirstInstanceOf(class'RPGO_UIArmory_PromotionHero'));
	UI.MC.SetNum("_width", Width);
}

exec function PSSetXOffset(int AdjustXOffset)
{
	local RPGO_UIArmory_PromotionHero UI;
	
	UI = RPGO_UIArmory_PromotionHero(`SCREENSTACK.GetFirstInstanceOf(class'RPGO_UIArmory_PromotionHero'));
	UI.MC.SetNum("_x", UI.MC.GetNum("_x") + AdjustXOffset);
}

exec function PSSetColumnWidth(int Offset = 200, int Width = 120)
{
	local RPGO_UIArmory_PromotionHero UI;
	local int i;

	UI = RPGO_UIArmory_PromotionHero(`SCREENSTACK.GetFirstInstanceOf(class'RPGO_UIArmory_PromotionHero'));
	for (i = 0; i < UI.Columns.Length; i++)
	{
		if (i == 5 || i ==6)
			UI.Columns[i].MC.SetNum("_width", Width);
		//UI.Columns[i].SetX(Offset + (i * Width));
		
	}
}

exec function PSScrollBarSetPos(int X, int Y, int Anchor = -1)
{
	local RPGO_UIArmory_PromotionHero UI;
	UI = RPGO_UIArmory_PromotionHero(`SCREENSTACK.GetFirstInstanceOf(class'RPGO_UIArmory_PromotionHero'));

	UI.Scrollbar.SetX(X);
	UI.Scrollbar.SetY(Y);

	if (Anchor > -1)
	{
		UI.Scrollbar.SetAnchor(Anchor);
	}
}

exec function PSScrollBarSetSize(int Width = 0, int Height = 0)
{
	local RPGO_UIArmory_PromotionHero UI;
	UI = RPGO_UIArmory_PromotionHero(`SCREENSTACK.GetFirstInstanceOf(class'RPGO_UIArmory_PromotionHero'));

	if (Width > 0)
	{
		UI.Scrollbar.SetWidth(Width);
	}

	if (Height > 0)
	{
		UI.Scrollbar.SetHeight(Height);
	}
}