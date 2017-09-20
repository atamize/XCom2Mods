class NMD_Stat_ShotAccuracy extends NMD_BaseStat;

const ID = 'ShotAccuracy';

var localized string m_strShots;

var int Hits;
var int Attempts;

function InitComponent()
{
	Hits = 0;
	Attempts = 0;
}

function AddShot(bool IsHit)
{
	if (IsHit)
	{
		Hits++;
	}
	Attempts++;
}

function int GetPercentage()
{
	local float pct;

	if (Attempts == 0)
		return 0;

	pct = float(Hits) / float(Attempts);

	return int(pct * 100);
}

function int GetValue(int UnitID)
{
	return GetPercentage();
}

function string GetName()
{
	return m_strShots;
}

function string GetDisplayValue()
{
	if (Attempts > 0)
	{
		return string(Hits) $ "/" $ string(Attempts) @ "(" $ GetPercentage() $ "%)";
	}
	
	return "--";
}

function name GetType()
{
	return ID;
}
