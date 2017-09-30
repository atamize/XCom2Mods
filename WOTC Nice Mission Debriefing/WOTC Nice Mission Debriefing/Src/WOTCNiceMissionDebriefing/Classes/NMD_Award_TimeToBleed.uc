class NMD_Award_TimeToBleed extends NMD_BaseAward;

function string GetLabel(XComGameState_Unit Unit)
{
	if (Unit.IsRobotic())
	{
		return class'NMD_MissionInfo'.default.m_strTimeToBleedRobot;
	}

	return super.GetLabel(Unit);
}
