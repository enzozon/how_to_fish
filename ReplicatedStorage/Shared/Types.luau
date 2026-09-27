--!strict

export type Module = {
	Init: ((self: any) -> ())?,
	Start: ((self: any) -> ())?,
}

export type Rarity = "Comum" | "Incomum" | "Raro" | "Épico"

export type FishDef = {
	id: string,
	name: string,
	island: number,
	lureTier: number, -- tier da isca que atrai esta espécie (LureDef.tier)
	rarity: Rarity,
	baseValue: number, -- $ antes dos multiplicadores de peso/raridade
	weightRange: { min: number, max: number }, -- kg
	aggressive: boolean,
	health: number?, -- só peixes agressivos
	pullStrength: number, -- 1..10, força dos puxões no minijogo
	color: Color3, -- cor do peixe em terra (greybox)
}

export type LureDef = {
	id: string,
	name: string,
	tier: number,
	island: number, -- ilha onde é liberada
	price: number,
}

export type RodDef = {
	id: string,
	name: string,
	price: number,
	strength: number, -- 1..10, reduz o ganho de tensão
	resistance: number, -- 1..10, tensão máxima
}

export type WeaponDef = {
	id: string,
	name: string,
	price: number,
	damage: number,
}

export type FoodDef = {
	id: string,
	name: string,
	hungerRestore: number, -- quanto de fome recupera ao comer
	baseValue: number, -- $ de venda
}

export type ItemData = {
	id: string, -- id de um config (Fish, Lures...)
	weight: number?, -- kg; só peixes
}

export type PlayerData = {
	money: number,
	inventory: { [string]: ItemData }, -- chave = uid do item
	equippedRod: string?, -- id em Rods; nil = sem vara
	equippedLure: string, -- id em Lures
	hunger: number, -- 0..MAX_HUNGER
}

return {}
