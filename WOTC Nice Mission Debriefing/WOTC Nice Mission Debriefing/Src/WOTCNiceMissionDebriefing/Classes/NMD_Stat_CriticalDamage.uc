class NMD_Stat_CriticalDamage extends NMD_BaseStat;

const ID = 'CriticalDamage';

function bool IsVisible()
{
	return false;
}

function name GetType()
{
	return ID;
}
