class NMD_Stat_WoundedDamage extends NMD_BaseStat;

const ID = 'WoundedDamage';

function bool IsVisible()
{
	return false;
}

function name GetType()
{
	return ID;
}
