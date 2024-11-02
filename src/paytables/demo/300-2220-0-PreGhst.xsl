<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;
					var bonusTotal = 0; 
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc)
					{
						var scenario = getScenario(jsonContext);
						var scenarioMainGame = getMainGameData(scenario);
						var scenarioSpinSymbs = getSpinSymbs(scenario);
						var scenarioBonusGame = getBonusGame(scenario);
						var scenarioInstantWins = getInstantWins(scenario);
						var convertedPrizeValues = (prizeValues.substring(1)).split("|");
						var prizeNames = (prizeNamesDesc.substring(1)).split(",");

						////////////////////
						// Parse Scenario //
						////////////////////

						const symbPrizes      = 'ABCDEF';
						const targetPrizes    = [30,27,24,21,18,15];
						const symbFeatures    = 'brtx';
						const symbAllFeatures = symbFeatures + 'q';
						const gridColsQty     = 10;

						var turnGrids      = [];
						var gridColumns    = [];
						var columnCells    = [];
						var cellData       = [];
						var turnGridScores = [];
						var turnFeatures   = [];
						var prizeScore     = 0;
						var featureScore   = [0,0,0,0];
						var turnsQty       = 6;
						var turnsIndex     = 0;
						var gridRowsQty    = 6;
						var doBonusGame    = false;
						var addRows        = 0;
						var spinSymb       = '';
						var cellFeature    = '';

						/////////////////////////////////////////////////////////
						// Get prize symbols collected, and features collected //
						/////////////////////////////////////////////////////////

 						while (turnsIndex <= turnsQty)
						{
							prizeScore = 0;
							featureScore = [0,0,0,0];
							addRows = 0;

							if (turnsIndex > 0)
							{
								spinSymb = scenarioSpinSymbs[turnsIndex - 1];

								if (spinSymb != 'I')
								{							
									for (var columnIndex = 0; columnIndex < gridColsQty; columnIndex++)
									{
										for (var rowIndex = gridRowsQty - 1; rowIndex >= 0; rowIndex--)
										{
											if (scenarioMainGame[columnIndex][2 * rowIndex] == spinSymb)
											{
												prizeScore++;
												cellFeature = scenarioMainGame[columnIndex][2 * rowIndex + 1];

												if (symbFeatures.indexOf(cellFeature) != -1)
												{
													switch(cellFeature)
													{
														case 'b':
															doBonusGame = true;
															break;
														case 'r':
															addRows++;
															break;
														case 't':
															turnsQty++;
															break;
														case 'x':
															break;
													}

													featureScore[symbFeatures.indexOf(cellFeature)]++;
												}

												scenarioMainGame[columnIndex] = (scenarioMainGame[columnIndex]).substr(0, 2 * rowIndex) + (scenarioMainGame[columnIndex]).substr(2 * (rowIndex + 1));
											}
										}
									}
								}

								gridRowsQty += addRows;
							}

							turnGridScores.push(prizeScore);
							turnFeatures.push(featureScore);

							/////////////////////////////////
							// Get grid data for each turn //
							/////////////////////////////////

							gridColumns = [];

							for (var columnIndex = 0; columnIndex < gridColsQty; columnIndex++)
							{
								columnCells = [];

								for (var rowIndex = 0; rowIndex < gridRowsQty; rowIndex++)
								{
									cellData = scenarioMainGame[columnIndex].substr(2 * rowIndex, 2).split("");
									columnCells.push(cellData);
								}

								gridColumns.push(columnCells);
							}

							turnGrids.push(gridColumns);

							turnsIndex++;
						}

						///////////////////////
						// Output Game Parts //
						///////////////////////

						const cellSize     = 24;
						const cellMargin   = 1;
						const cellText1X   = 13;
						const cellText2X   = 8;
						const cellText2XF  = 18;
						const cellText1Y   = 15;
						const cellText2Y   = 10;
						const colourYellow = '#ffe699';
						const colourPink   = '#ffccff';
						const colourPurple = '#cc99ff';
						const colourBlue   = '#99ccff';
						const colourRed    = '#ff6699';
						const colourGreen  = '#c6e0b4';
						const colourBlack  = '#000000';
						const colourWhite  = '#ffffff';
						const colourOrange = '#ffa88f';
						const colourTan    = '#ffcc99';
						const colourCyan   = '#ddffff';
						const symbColours  = [colourYellow, colourPink, colourPurple, colourBlue, colourRed, colourGreen];
						
						var r = [];

						var symbPrize        = '';
						var symbFeature      = '';
						var canvasIdStr      = '';
						var emotiSymbolStr   = '';
						var featureSymbolStr = '';
						var canvasCtxStr     = '';
						var boxColourStr     = '';
						var symbDesc         = '';
						var symbTarget       = '';

						function showSymb(AcanvasIdStr, AcanvasSymbStr, AboxColourStr, Aprize, Afeature)
						{
							var textPrizeX = (Afeature == undefined) ? cellText1X : cellText2X;
							var canvasCtxStr = 'canvasContext' + AcanvasSymbStr;

							r.push('<canvas id="' + AcanvasIdStr + '" width="' + (cellSize + 2 * cellMargin).toString() + '" height="' + (cellSize + 2 * cellMargin).toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + AcanvasSymbStr + ' = document.getElementById("' + AcanvasIdStr + '");');
							r.push('var ' + canvasCtxStr + ' = ' + AcanvasSymbStr + '.getContext("2d");');
							r.push(canvasCtxStr + '.font = "bold 14px Arial";');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');
							r.push(canvasCtxStr + '.strokeRect(' + (cellMargin + 0.5).toString() + ', ' + (cellMargin + 0.5).toString() + ', ' + cellSize.toString() + ', ' + cellSize.toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + AboxColourStr + '";');
							r.push(canvasCtxStr + '.fillRect(' + (cellMargin + 1.5).toString() + ', ' + (cellMargin + 1.5).toString() + ', ' + (cellSize - 2).toString() + ', ' + (cellSize - 2).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + colourBlack + '";');
							r.push(canvasCtxStr + '.fillText("' + Aprize + '", ' + textPrizeX.toString() + ', ' + cellText1Y.toString() + ');');

							if (Afeature != undefined)
							{
								r.push(canvasCtxStr + '.font = "bold 10px Arial";');
								r.push(canvasCtxStr + '.fillText("' + Afeature.toUpperCase() + '", ' + cellText2XF.toString() + ', ' + cellText2Y.toString() + ');');
							}

							r.push('</script>');
						}

						/////////////////
						// Symbols Key //
						/////////////////

 						r.push('<div style="float:left; margin-right:50px">');
						r.push('<p>' + getTranslationByName("titleSymbolsKey", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable" style="table-layout:fixed">');
						r.push('<tr class="tablehead">');
						r.push('<td>' + getTranslationByName("keySymbol", translations) + '</td>');
						r.push('<td>' + getTranslationByName("keyDescription", translations) + '</td>');
						r.push('<td>' + getTranslationByName("keyTarget", translations) + '</td>');
						r.push('</tr>');
						
						for (var prizeIndex = 0; prizeIndex < symbPrizes.length; prizeIndex++)
						{
							symbPrize      = symbPrizes[prizeIndex];
							canvasIdStr    = 'cvsKeySymb' + symbPrize;
							emotiSymbolStr = 'emotiSymb' + symbPrize;
							boxColourStr   = symbColours[prizeIndex];
							symbDesc       = 'symb' + symbPrize;
							symbTarget     = targetPrizes[prizeIndex];

							r.push('<tr class="tablebody">');
							r.push('<td align="center">');

							showSymb(canvasIdStr, emotiSymbolStr, boxColourStr, symbPrize);
							
							r.push('</td>');
							r.push('<td>' + getTranslationByName(symbDesc, translations) + '</td>');
							r.push('<td>' + symbTarget.toString() + '</td>');
							r.push('</tr>');
						}

						r.push('</table>');
						r.push('</div>');

						//////////////////
						// Features Key //
						//////////////////

 						r.push('<div style="float:left">');
						r.push('<p>' + getTranslationByName("titleFeaturesKey", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable" style="table-layout:fixed">');
						r.push('<tr class="tablehead">');
						r.push('<td>' + getTranslationByName("keySymbol", translations) + '</td>');
						r.push('<td>' + getTranslationByName("keyDescription", translations) + '</td>');
						r.push('</tr>');
						
						for (var featureIndex = 0; featureIndex < symbAllFeatures.length; featureIndex++)
						{
							symbFeature      = symbAllFeatures[featureIndex];
							canvasIdStr      = 'cvsKeyFeature' + symbFeature;
							featureSymbolStr = 'featureSymb' + symbFeature;
							featureDesc      = 'feature' + symbFeature.toUpperCase();

							r.push('<tr class="tablebody">');
							r.push('<td align="center">');

							showSymb(canvasIdStr, featureSymbolStr, colourWhite, "#", symbFeature);
							
							r.push('</td>');
							r.push('<td>' + getTranslationByName(featureDesc, translations) + '</td>');
							r.push('</tr>');
						}

						r.push('</table>');
						r.push('</div>');

						///////////////
						// Main Game //
						///////////////

						var turnStr          = '';
						var turnGridStr      = '';
						var turnInfo         = '';
						var cellX            = 0;
						var cellY            = 0;
						var cellTextX        = 0;
						var cellTextY        = 0;
						var gridScores       = [0,0,0,0,0,0];
						var multiScores      = [0,0,0,0,0,0];
						var gridCanvasWidth  = gridColsQty * cellSize + 2 * cellMargin;
						var gridCanvasHeight = 0;
						var indexIW          = 0;

						turnsQty    = 6;
						gridRowsQty = 6;
						
						r.push('<p style="clear:both"><br>' + getTranslationByName("mainGame", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable" style="table-layout:fixed">');

						for (var turnIndex = 0; turnIndex < scenarioSpinSymbs.length + 1; turnIndex++)
						{
							if (turnFeatures[turnIndex][symbFeatures.indexOf('t')] != 0)
							{
								turnsQty += turnFeatures[turnIndex][symbFeatures.indexOf('t')];
							}
							else if (turnFeatures[turnIndex][symbFeatures.indexOf('r')] != 0)
							{
								gridRowsQty += turnFeatures[turnIndex][symbFeatures.indexOf('r')];
							}

							///////////////
							// Turn Info //
							///////////////

							turnStr = (turnIndex == 0) ? getTranslationByName("initialGrid", translations) :
														 getTranslationByName("turnIndex", translations) + ' ' + turnIndex.toString() + ' ' + getTranslationByName("turnOf", translations) + ' ' + turnsQty.toString();

							canvasIdStr  = 'cvsTurn' + turnIndex.toString();
							turnSymbStr  = 'turnSymb' + turnIndex.toString();
							spinSymb     = scenarioSpinSymbs[turnIndex - 1];
							prizeIndex   = symbPrizes.indexOf(spinSymb);
							boxColourStr = (prizeIndex != -1) ? symbColours[prizeIndex] : colourCyan;
							turnInfo     = (prizeIndex != -1) ? getTranslationByName("symbsCollected", translations) + ' : ' + (turnGridScores[turnIndex]).toString() : getTranslationByName("instantWin", translations);

							r.push('<tr class="tablebody">');
							r.push('<td valign="top">' + turnStr);

							if (turnIndex > 0)
							{
								r.push('<br>&nbsp;');
								r.push('<table border="0" cellpadding="0" cellspacing="0" class="gameDetailsTable" style="table-layout:fixed">');
								r.push('<tr class="tablebody">');								
								r.push('<td>' + getTranslationByName("spinSymb", translations) + '&nbsp;</td>');
								r.push('<td align="center">');

								showSymb(canvasIdStr, turnSymbStr, boxColourStr, spinSymb);

								r.push('</td>');
								r.push('</tr>');
								r.push('</table>');
								r.push('<br>');
								r.push(turnInfo);

								if (prizeIndex != -1)
								{
									gridScores[prizeIndex] += turnGridScores[turnIndex];
								}
							}

							r.push('</td>');

							////////////////////////
							// Features collected //
							////////////////////////

							r.push('<td valign="top" style="padding-left:50px">');

							if ((turnFeatures[turnIndex]).some(function (e) {return e > 0}))
							{
								r.push(getTranslationByName("featuresCollected", translations));
								r.push('<br>&nbsp;');
								r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable" style="table-layout:fixed">');

								for (var featureIndex = 0; featureIndex < symbFeatures.length; featureIndex++)
								{
									if (turnFeatures[turnIndex][featureIndex] > 0)
									{
										symbFeature      = symbFeatures[featureIndex];
										canvasIdStr      = 'cvsFeature' + turnIndex.toString() + symbFeature;
										featureSymbolStr = 'featureSymb' + symbFeature;
										spinSymb         = scenarioSpinSymbs[turnIndex - 1];
										prizeIndex       = symbPrizes.indexOf(spinSymb);
										boxColourStr     = symbColours[prizeIndex];

										r.push('<tr class="tablebody">');
										r.push('<td align="center">');

										showSymb(canvasIdStr, featureSymbolStr, boxColourStr, spinSymb, symbFeature);

										r.push('</td>');
										r.push('<td>x ' + (turnFeatures[turnIndex][featureIndex]).toString() + '</td>');
										r.push('</tr>');

										if (symbFeature == 'x')
										{
											multiScores[prizeIndex] += turnFeatures[turnIndex][featureIndex];
										}
									}
								}

								r.push('</table>');
							}

							r.push('</td>');

							//////////////////
							// Grid symbols //
							//////////////////

							canvasIdStr      = 'cvsGrid' + turnIndex.toString();
							turnGridStr      = 'turnGrid' + turnIndex.toString();
							canvasCtxStr     = 'canvasContext' + turnIndex.toString();
							gridCanvasHeight = gridRowsQty * cellSize + 2 * cellMargin;

							r.push('<td style="padding-left:50px; padding-right:50px; padding-bottom:25px">');
							r.push('<canvas id="' + canvasIdStr + '" width="' + gridCanvasWidth.toString() + '" height="' + gridCanvasHeight.toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + turnGridStr + ' = document.getElementById("' + canvasIdStr + '");');
							r.push('var ' + canvasCtxStr + ' = ' + turnGridStr + '.getContext("2d");');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');

							for (var gridCol = 0; gridCol < gridColsQty; gridCol++)
							{
								for (var gridRow = 0; gridRow < gridRowsQty; gridRow++)
								{
									symbPrize    = turnGrids[turnIndex][gridCol][gridRow][0];
									symbFeature  = turnGrids[turnIndex][gridCol][gridRow][1];
									prizeIndex   = symbPrizes.indexOf(symbPrize);
									boxColourStr = symbColours[prizeIndex];
									cellX        = gridCol * cellSize;
									cellY        = (gridRowsQty - gridRow - 1) * cellSize;
									cellTextX    = (symbFeature == '.') ? cellX + cellText1X : cellX + cellText2X;

									r.push(canvasCtxStr + '.font = "bold 14px Arial";');
									r.push(canvasCtxStr + '.strokeRect(' + (cellX + cellMargin + 0.5).toString() + ', ' + (cellY + cellMargin + 0.5).toString() + ', ' + cellSize.toString() + ', ' + cellSize.toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + boxColourStr + '";');
									r.push(canvasCtxStr + '.fillRect(' + (cellX + cellMargin + 1.5).toString() + ', ' + (cellY + cellMargin + 1.5).toString() + ', ' + (cellSize - 2).toString() + ', ' + (cellSize - 2).toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + colourBlack + '";');
									r.push(canvasCtxStr + '.fillText("' + symbPrize + '", ' + cellTextX.toString() + ', ' + (cellY + cellText1Y).toString() + ');');

									if (symbAllFeatures.indexOf(symbFeature) != -1)
									{
										r.push(canvasCtxStr + '.font = "bold 10px Arial";');
										r.push(canvasCtxStr + '.fillText("' + symbFeature.toUpperCase() + '", ' + (cellX + cellText2XF).toString() + ', ' + (cellY + cellText2Y).toString() + ');');
									}
								}
							}

							r.push('</script>');							
							r.push('</td>');

							///////////////////
							// Total symbols //
							///////////////////

							r.push('<td valign="top" style="padding-right:50px">');

							if (turnIndex > 0)
							{
								r.push(getTranslationByName("symbsCollectedTotal", translations));
								r.push('<br>&nbsp;');
								r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable" style="table-layout:fixed">');
								r.push('<tr class="tablebody">');

								for (var prizeIndex = 0; prizeIndex < symbPrizes.length; prizeIndex++)
								{
									symbPrize      = symbPrizes[prizeIndex];
									canvasIdStr    = 'cvsSymbTotal' + turnIndex.toString() + symbPrize;
									emotiSymbolStr = 'emotiSymb' + symbPrize;
									boxColourStr   = symbColours[prizeIndex];

									r.push('<td align="center">');

									showSymb(canvasIdStr, emotiSymbolStr, boxColourStr, symbPrize);
							
									r.push('</td>');
								}

								r.push('</tr>');
								r.push('<tr class="tablebody">');

								for (var prizeIndex = 0; prizeIndex < symbPrizes.length; prizeIndex++)
								{
									r.push('<td align="center">' + (gridScores[prizeIndex]).toString() + '</td>');
								}
								
								r.push('</tr>');
								r.push('</table>');
							}

							r.push('</td>');

							////////////////////
							// Main Game Wins //
							////////////////////

							var prizeStr  = '';
							var prizeText = '';
							var isIW      = false;

							spinSymb   = scenarioSpinSymbs[turnIndex - 1];
							prizeIndex = symbPrizes.indexOf(spinSymb);
							isIW       = (spinSymb == 'I');

							r.push('<td valign="top">');

							if (gridScores[prizeIndex] >= targetPrizes[prizeIndex] || isIW)
							{
								canvasIdStr  = 'cvsPrize' + turnIndex.toString() + spinSymb;
								turnSymbStr  = 'prizeSymb' + turnIndex.toString() + spinSymb;	
								boxColourStr = (isIW) ? colourCyan : symbColours[prizeIndex];
								prizeText    = (isIW) ? 'IW' + scenarioInstantWins[indexIW] : spinSymb;
								prizeStr     = convertedPrizeValues[getPrizeNameIndex(prizeNames, prizeText)] + ((isIW) ? '' : ' x ' + Math.pow(2, multiScores[prizeIndex]).toString());

								r.push(getTranslationByName("winPrize", translations));
								r.push('<br>&nbsp;');
								r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable" style="table-layout:fixed">');
								r.push('<tr class="tablebody">');
								r.push('<td align="center">');

								showSymb(canvasIdStr, turnSymbStr, boxColourStr, spinSymb);

								r.push('</td>');
								r.push('<td>' + prizeStr + '</td>');
								r.push('</tr>');
								r.push('</table>');

								if (isIW)
								{
									indexIW++;
								}
							}

							r.push('</td>');
							r.push('</tr>');
						}

						r.push('</table>');

						////////////////
						// Bonus Game //
						////////////////

						if (doBonusGame)
						{
							const symbBonuses      = 'TWXZYVU';						
							const targetBonuses    = [2,3,4,5,4,3,2];
							const bonusTurnsPerRow = 7;
							const bonusTurnsRowQty = 2;
							const bonusTurnsQty    = bonusTurnsPerRow * bonusTurnsRowQty;
							const bonusCanvasSize  = symbBonuses.length * cellSize + 2 * cellMargin;
							const pegRadius        = 7;

							var symbBonus    = '';
							var bonusSymbStr = '';
							var bonusScores  = [0,0,0,0,0,0,0];
							var pegX         = 0;
							var pegY         = 0;
							var ballPos      = 0;

							/////////////
							// Targets //
							/////////////

							r.push('<p>' + getTranslationByName("bonusGame", translations) + '</p>');
							r.push('<p>' + getTranslationByName("bonusGameTargets", translations) + '</p>');
							
							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable" style="table-layout:fixed">');
							r.push('<tr class="tablebody">');

							for (var bonusIndex = 0; bonusIndex < symbBonuses.length; bonusIndex++)
							{
								symbBonus    = symbBonuses[bonusIndex];
								canvasIdStr  = 'cvsBonusTarget' + symbBonus;
								bonusSymbStr = 'bonusSymb' + symbBonus;

								r.push('<td align="center">');

								showSymb(canvasIdStr, bonusSymbStr, colourOrange, symbBonus);

								r.push('</td>');
							}

							r.push('</tr>');
							r.push('<tr class="tablebody">');

							for (var bonusIndex = 0; bonusIndex < symbBonuses.length; bonusIndex++)
							{
								r.push('<td align="center">' + (targetBonuses[bonusIndex]).toString() + '</td>');
							}
							
							r.push('</tr>');
							r.push('</table>');
							r.push('<br>');

							////////////////
							// Ball drops //
							////////////////

							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable" style="table-layout:fixed">');

							for (var bonusRows = 0; bonusRows < bonusTurnsRowQty; bonusRows++)
							{
								r.push('<tr class="tablebody">');

								for (var bonusCols = 0; bonusCols < bonusTurnsPerRow; bonusCols++)
								{
									turnIndex    = bonusRows * bonusTurnsPerRow + bonusCols;
									turnStr      = getTranslationByName("turnIndex", translations) + ' ' + (turnIndex + 1).toString() + ' ' + getTranslationByName("turnOf", translations) + ' ' + bonusTurnsQty.toString();
									canvasIdStr  = 'cvsBonus' + turnIndex.toString();
									turnBonusStr = 'turnBonus' + turnIndex.toString();
									canvasCtxStr = 'canvasContext' + turnBonusStr;
									ballPos      = 0;

									r.push('<td valign="top" style="padding-right:25px">' + turnStr);
									r.push('<br><br>&nbsp;');
									r.push('<canvas id="' + canvasIdStr + '" width="' + bonusCanvasSize.toString() + '" height="' + bonusCanvasSize.toString() + '"></canvas>');
									r.push('<script>');
									r.push('var ' + turnBonusStr + ' = document.getElementById("' + canvasIdStr + '");');
									r.push('var ' + canvasCtxStr + ' = ' + turnBonusStr + '.getContext("2d");');
									r.push(canvasCtxStr + '.textAlign = "center";');
									r.push(canvasCtxStr + '.textBaseline = "middle";');

									for (var pegRow = 1; pegRow < symbBonuses.length; pegRow++)
									{
										for (var pegIndex = 0; pegIndex < pegRow; pegIndex++)
										{
											pegX = (symbBonuses.length - pegRow + 1) * cellSize / 2 + (pegIndex * cellSize) + 1.5;
											pegY = (pegRow - 1) * cellSize + pegRadius + 2.5;

											r.push(canvasCtxStr + '.beginPath();');
											r.push(canvasCtxStr + '.arc(' + pegX.toString() + ', ' + pegY.toString() + ', ' + pegRadius.toString() + ', 0, 2*Math.PI);');
											r.push(canvasCtxStr + '.stroke();');

											if (pegIndex == ballPos)
											{
												r.push(canvasCtxStr + '.arc(' + pegX.toString() + ', ' + pegY.toString() + ', ' + (pegRadius-1).toString() + ', 0, 2*Math.PI);');
												r.push(canvasCtxStr + '.fillStyle = "' + colourTan + '";');
												r.push(canvasCtxStr + '.fill();');
											}
										}

										if (scenarioBonusGame[turnIndex][pegRow - 1] == 'R')
										{
											ballPos++;
										}
									}

									bonusScores[ballPos]++;

									for (var bonusIndex = 0; bonusIndex < symbBonuses.length; bonusIndex++)
									{
										cellX        = (bonusIndex * cellSize);
										cellY        = (symbBonuses.length - 1)  * cellSize;
										boxColourStr = (bonusIndex == ballPos) ? ((bonusScores[ballPos] == targetBonuses[ballPos]) ? colourOrange : colourTan) : colourWhite;

										r.push(canvasCtxStr + '.font = "bold 14px Arial";');
										r.push(canvasCtxStr + '.strokeRect(' + (cellX + cellMargin + 0.5).toString() + ', ' + (cellY + 0.5).toString() + ', ' + cellSize.toString() + ', ' + cellSize.toString() + ');');
										r.push(canvasCtxStr + '.fillStyle = "' + boxColourStr + '";');
										r.push(canvasCtxStr + '.fillRect(' + (cellX + cellMargin + 1.5).toString() + ', ' + (cellY + 1.5).toString() + ', ' + (cellSize - 2).toString() + ', ' + (cellSize - 2).toString() + ');');
										r.push(canvasCtxStr + '.fillStyle = "' + colourBlack + '";');
										r.push(canvasCtxStr + '.fillText("' + (bonusScores[bonusIndex]).toString() + '", ' + (cellX + cellText1X).toString() + ', ' + (cellY + cellText1Y).toString() + ');');
									}

									r.push('</script>');

									////////////////////
									//Bonus Game Wins //
									////////////////////

									r.push('<br>&nbsp;');

									if (bonusScores[ballPos] == targetBonuses[ballPos])
									{
										symbBonus    = symbBonuses[ballPos];
										canvasIdStr  = 'cvsPrize' + symbBonus;
										bonusSymbStr = 'prizeSymb' + symbBonus;
										prizeStr     = convertedPrizeValues[getPrizeNameIndex(prizeNames, symbBonus)];

										r.push('<br>&nbsp;');
										r.push(getTranslationByName("winPrize", translations));
										r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable" style="table-layout:fixed">');
										r.push('<tr class="tablebody">');
										r.push('<td align="center">');

										showSymb(canvasIdStr, bonusSymbStr, colourOrange, symbBonus);

										r.push('</td>');
										r.push('<td>' + prizeStr + '</td>');
										r.push('</tr>');
										r.push('</table>');
									}

									r.push('</td>');
								}

								r.push('</tr>');
							}

							r.push('</table>');
						}						

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
 							{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 								r.push('</td>');
	 							r.push('</tr>');
							}
							r.push('</table>');
						}
						return r.join('');
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");

						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}

						return "";
					}

					// Input: Json document string containing 'scenario' at root level.
					// Output: Scenario value.
					function getScenario(jsonContext)
					{
						// Parse json and retrieve scenario string.
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						// Trim null from scenario string.
						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}

					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}

					function getMainGameData(scenario)
					{
						var mainGameData = scenario.split("|")[0];

						return mainGameData.split(",");
					}

					function getSpinSymbs(scenario)
					{
						return scenario.split("|")[1];
					}

					function getBonusGame(scenario)
					{
						var bonusGameData = scenario.split("|")[2];

						return bonusGameData.split(",");
					}

					function getInstantWins(scenario)
					{
						return scenario.split("|")[3];
					}

					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						for(var i = 0; i < prizeNames.length; ++i)
						{
							if(prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}

					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
